import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:developer_os/features/github/data/github_service.dart';
import 'package:developer_os/features/github/domain/models/github_models.dart';
import 'package:developer_os/features/projects/domain/models/project.dart';
import 'package:developer_os/features/projects/data/repositories/project_repository.dart';
import 'package:developer_os/features/auth/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// المفاتيح الثابتة
const _storage = FlutterSecureStorage();
const String _tokenKey = 'github_token';
const String _usernameKey = 'github_username';

// المخزن الآمن للتوكن فقط
const _secureStorage = FlutterSecureStorage();

final githubTokenProvider =
    StateNotifierProvider<GitHubTokenNotifier, String?>((ref) {
  // بنرمي UnimplementedError عشان نضمن إننا باصينا الـ Token في الـ ProviderScope جوة الـ main
  throw UnimplementedError();
});

// =====================
// GitHub Token Notifier
// =====================
class GitHubTokenNotifier extends StateNotifier<String?> {
  final Ref _ref;

  // 1. هنا بنخليه يبدأ بـ null عادي جداً
  GitHubTokenNotifier(this._ref, String? initialToken) : super(initialToken) {
    // 2. وبمجرد ما الـ Class يتكريت، بنخليه يروح يقرأ التوكن فوراً
    _loadTokenFromStorage();
  }

  Future<void> _loadTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('github_token');
    if (token != null) {
      debugPrint(
          '🔑 [GitHubTokenNotifier]: Token loaded from SharedPreferences: $token');
      state = token; // هنا بنحدث الـ State أول ما الداتا تيجي
    }
  }

  Future<bool> saveToken(String token) async {
    try {
      final service = GitHubService(token: token);
      final isValid = await service.validateToken();
      if (!isValid) return false;

      final user = await service.getAuthenticatedUser();
      final username = user['login'] as String;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('github_token', token);
      await prefs.setString('github_username', username);

      debugPrint('💾 [saveToken]: Token and Username saved successfully!');

      state = token;
      await _importReposAsProjects(service, username);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _importReposAsProjects(
      GitHubService service, String username) async {
    try {
      final uid = _ref.read(currentUserProvider)?.uid;
      if (uid == null) return;

      final repos = await service.getUserRepos(username);
      final repo = _ref.read(projectRepositoryProvider);

      final existingProjects = await repo.getProjectsOnce(uid);
      final existingGithubUrls =
          existingProjects.map((p) => p.githubUrl).toSet();

      for (final r in repos) {
        final repoUrl = r['html_url'] as String? ?? '';

        if (existingGithubUrls.contains(repoUrl)) continue;

        final lang = r['language'] as String?;
        final techStack = lang != null ? [lang] : <String>[];

        final project = Project(
          id: '',
          uid: uid,
          name: r['name'] as String? ?? 'Unknown',
          description: (r['description'] as String?)?.isNotEmpty == true
              ? r['description'] as String
              : 'Imported from GitHub',
          techStack: techStack,
          projectType: 'Web Application',
          targetPlatform: 'Web (Browser)',
          status: r['archived'] == true ? 'archived' : 'active',
          githubUrl: repoUrl,
          roadmap: const [],
          createdAt: r['created_at'] != null
              ? DateTime.tryParse(r['created_at']) ?? DateTime.now()
              : DateTime.now(),
        );

        await repo.createProject(project);
      }
    } catch (e) {
      debugPrint('❌ [_importReposAsProjects] Error: $e');
    }
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. بنمسح التوكن من الـ SharedPreferences عشان ميقراش تاني لما نقفل ونفتح
    await prefs.remove('github_token');

    // 2. بنمسح اليوزر نيم كمان
    await prefs.remove('github_username');

    // 3. بنمسح من الـ SecureStorage للاحتياط لو كان فيه بقايا قديمة
    await _secureStorage.delete(key: 'github_token');

    // 4. بنصفر الـ State عشان الـ UI يفهم فوراً إن مفيش مستخدم
    state = null;

    debugPrint('🗑️ [clearToken]: All storage and state cleared successfully!');
  }
}

// =====================
// Username Provider
// =====================
final githubUsernameProvider = FutureProvider<String?>((ref) async {
  final token = ref.watch(githubTokenProvider);
  if (token == null) return null;

  // بنقرأ اليوزر نيم من الـ SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final savedUsername = prefs.getString(_usernameKey);

  if (savedUsername != null) {
    debugPrint(
        '👤 [githubUsernameProvider]: Loaded from SharedPreferences: $savedUsername');
    return savedUsername;
  }

  // لو مش موجود (أول مرة مثلاً)، هيروح يجيبه من الـ API
  try {
    debugPrint(
        '🚀 [githubUsernameProvider]: Fetching fresh username from GitHub...');
    final service = GitHubService(token: token);
    final user = await service.getAuthenticatedUser();
    final username = user['login'] as String?;

    if (username != null) {
      await prefs.setString(_usernameKey, username);
    }

    debugPrint('👤 [githubUsernameProvider]: Successfully fetched: $username');
    return username;
  } catch (e) {
    debugPrint('❌ [githubUsernameProvider] Error: $e');
    return null;
  }
});

// =====================
// Stats Provider
// =====================
final githubStatsProvider = FutureProvider<GitHubUserStats?>((ref) async {
  final token = ref.watch(githubTokenProvider);
  if (token == null) return null;

  final usernameAsync = ref.watch(githubUsernameProvider);

  return usernameAsync.when(
    data: (username) async {
      if (username == null) {
        debugPrint(
            'ℹ️ [githubStatsProvider]: Username is null, cannot fetch stats');
        return null;
      }

      try {
        debugPrint('🚀 [githubStatsProvider]: Fetching stats for $username...');
        final service = GitHubService(token: token);
        final statsMap = await service.getUserStats(username);

        debugPrint('✅ [githubStatsProvider]: Stats fetched successfully!');
        return GitHubUserStats.fromMap(statsMap);
      } catch (e) {
        debugPrint('❌ [githubStatsProvider] Error: $e');
        return null;
      }
    },
    loading: () {
      debugPrint('⏳ [githubStatsProvider]: Waiting for username to resolve...');
      return null;
    },
    error: (err, stack) {
      debugPrint('❌ [githubStatsProvider]: Error: $err');
      return null;
    },
  );
});

// =====================
// Repos Provider
// =====================
final githubReposProvider = FutureProvider<List<GitHubRepo>>((ref) async {
  final token = ref.watch(githubTokenProvider);
  final prefs = await SharedPreferences.getInstance();
  final username = prefs.getString(_usernameKey);
  if (token == null) return [];

  debugPrint('👤 [Repos loaded]: Loaded from SharedPreferences: $username');

  if (username == null) return [];

  final service = GitHubService(token: token);
  final repos = await service.getUserRepos(username);
  return repos.map((r) => GitHubRepo.fromMap(r)).toList();
});

// =====================
// Create Repo
// =====================
final createGitHubRepoProvider =
    StateNotifierProvider<CreateRepoNotifier, AsyncValue<String?>>((ref) {
  return CreateRepoNotifier(ref);
});

class CreateRepoNotifier extends StateNotifier<AsyncValue<String?>> {
  final Ref _ref;

  CreateRepoNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<String?> createRepo({
    required String name,
    required String description,
    bool isPrivate = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final token = _ref.read(githubTokenProvider);
      if (token == null) {
        state = const AsyncValue.data(null);
        return null;
      }

      final service = GitHubService(token: token);
      final repo = await service.createRepo(
        name: name,
        description: description,
        isPrivate: isPrivate,
      );

      final url = repo['html_url'] as String;
      state = AsyncValue.data(url);
      return url;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return null;
    }
  }
}

// =====================
// Delete Repo
// =====================
final deleteGitHubRepoProvider =
    StateNotifierProvider<DeleteRepoNotifier, AsyncValue<bool>>((ref) {
  return DeleteRepoNotifier(ref);
});

class DeleteRepoNotifier extends StateNotifier<AsyncValue<bool>> {
  final Ref _ref;

  DeleteRepoNotifier(this._ref) : super(const AsyncValue.data(false));

  Future<bool> deleteRepo(String githubUrl) async {
    state = const AsyncValue.loading();
    try {
      final token = _ref.read(githubTokenProvider);
      if (token == null) {
        state = const AsyncValue.data(false);
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString(_usernameKey);


      if (username == null) {
        state = const AsyncValue.data(false);
        return false;
      }

      // استخرج اسم الـ repo من الـ URL
      // مثال: https://github.com/user/repo-name → repo-name
      final uri = Uri.parse(githubUrl);
      final segments = uri.pathSegments;
      if (segments.length < 2) {
        state = const AsyncValue.data(false);
        return false;
      }
      final repoName = segments[1];

      final service = GitHubService(token: token);
      final success = await service.deleteRepo(username, repoName);

      state = AsyncValue.data(success);
      debugPrint('👤 [githubRepo delete]: $repoName Successfully deleted: $username');
      return success;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }
}

// =====================
// Repo Files Provider
// =====================
final repoFilesProvider =
    FutureProvider.family<List<GitHubFile>, RepoFilesParams>(
  (ref, params) async {
    final token = ref.watch(githubTokenProvider);
    if (token == null) return [];

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_usernameKey);
    if (username == null) return [];

    debugPrint('👤 [Repos files loaded]: Loaded from SharedPreferences: $username');

    final service = GitHubService(token: token);
    final files = await service.getRepoFiles(username, params.repoName,
        path: params.path);

    return files.map((f) => GitHubFile.fromMap(f)).toList();
  },
);

class RepoFilesParams {
  final String repoName;
  final String path;

  const RepoFilesParams({required this.repoName, this.path = ''});

  @override
  bool operator ==(Object other) =>
      other is RepoFilesParams &&
      other.repoName == repoName &&
      other.path == path;

  @override
  int get hashCode => Object.hash(repoName, path);
}

// =====================
// File Content Provider
// =====================
final fileContentProvider =
    FutureProvider.family<String?, FileContentParams>((ref, params) async {
  final token = ref.watch(githubTokenProvider);
  if (token == null) return null;

  final prefs = await SharedPreferences.getInstance();
  final username = prefs.getString(_usernameKey);

  debugPrint('👤 [Repos file content loaded]: Loaded from SharedPreferences: $username');

  if (username == null) return null;

  final service = GitHubService(token: token);
  return await service.getFileContent(
      username, params.repoName, params.filePath);
});

class FileContentParams {
  final String repoName;
  final String filePath;

  const FileContentParams({required this.repoName, required this.filePath});

  @override
  bool operator ==(Object other) =>
      other is FileContentParams &&
      other.repoName == repoName &&
      other.filePath == filePath;

  @override
  int get hashCode => Object.hash(repoName, filePath);
}
