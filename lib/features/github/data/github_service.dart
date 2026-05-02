import 'dart:convert';
import 'package:http/http.dart' as http;

class GitHubService {
  static const String _baseUrl = 'https://api.github.com';
  final String token;

  GitHubService({required this.token});

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
      };

  // =====================
  // USER
  // =====================
  Future<Map<String, dynamic>> getAuthenticatedUser() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/user'),
      headers: _headers,
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('GitHub API error: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getUserProfile(String username) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/$username'),
      headers: _headers,
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('User not found: $username');
  }

  // =====================
  // REPOS
  // =====================
  Future<List<dynamic>> getUserRepos(String username) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/$username/repos?sort=updated&per_page=100'),
      headers: _headers,
    );
    if (response.statusCode == 200) return json.decode(response.body);
    return [];
  }

  Future<Map<String, dynamic>> createRepo({
    required String name,
    required String description,
    bool isPrivate = false,
  }) async {
    final cleanName = name
        .toLowerCase()
        .replaceAll(' ', '-')
        .replaceAll(RegExp(r'[^a-z0-9\-_.]'), '');

    final response = await http.post(
      Uri.parse('$_baseUrl/user/repos'),
      headers: _headers,
      body: json.encode({
        'name': cleanName,
        'description': description,
        'private': isPrivate,
        'auto_init': true,
      }),
    );

    if (response.statusCode == 201) return json.decode(response.body);
    throw Exception('Failed to create repo: ${response.body}');
  }

  // =====================
  // DELETE REPO
  // =====================
  Future<bool> deleteRepo(String username, String repoName) async {
    // نجيب اسم الـ repo من الـ URL
    // مثال: https://github.com/user/repo-name → repo-name
    final response = await http.delete(
      Uri.parse('$_baseUrl/repos/$username/$repoName'),
      headers: _headers,
    );
    // 204 = deleted successfully
    return response.statusCode == 204;
  }

  // =====================
  // REPO FILES (TREE)
  // =====================
  Future<List<Map<String, dynamic>>> getRepoFiles(
      String username, String repoName,
      {String path = ''}) async {
    final url = path.isEmpty
        ? '$_baseUrl/repos/$username/$repoName/contents'
        : '$_baseUrl/repos/$username/$repoName/contents/$path';

    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // جيب محتوى ملف معين
  Future<String?> getFileContent(String username, String repoName,
      String filePath) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/repos/$username/$repoName/contents/$filePath'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // المحتوى بيجي base64
      if (data['encoding'] == 'base64' && data['content'] != null) {
        final encoded = (data['content'] as String).replaceAll('\n', '');
        return utf8.decode(base64.decode(encoded));
      }
    }
    return null;
  }

  // =====================
  // STATS
  // =====================
  Future<Map<String, dynamic>> getUserStats(String username) async {
    final profileFuture = getUserProfile(username);
    final reposFuture = getUserRepos(username);

    final results = await Future.wait([profileFuture, reposFuture]);
    final profile = results[0] as Map<String, dynamic>;
    final repos = results[1] as List<dynamic>;

    int totalStars = 0;
    int totalForks = 0;
    Map<String, int> languages = {};

    for (final repo in repos) {
      totalStars += (repo['stargazers_count'] as int? ?? 0);
      totalForks += (repo['forks_count'] as int? ?? 0);
      final lang = repo['language'] as String?;
      if (lang != null) {
        languages[lang] = (languages[lang] ?? 0) + 1;
      }
    }

    String? topLanguage;
    if (languages.isNotEmpty) {
      topLanguage =
          languages.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    return {
      'profile': profile,
      'total_repos': profile['public_repos'] ?? 0,
      'followers': profile['followers'] ?? 0,
      'following': profile['following'] ?? 0,
      'total_stars': totalStars,
      'total_forks': totalForks,
      'top_language': topLanguage,
      'languages': languages,
      'repos': repos,
    };
  }

  // =====================
  // VALIDATE TOKEN
  // =====================
  Future<bool> validateToken() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/user'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}