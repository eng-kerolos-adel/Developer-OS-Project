class GitHubRepo {
  final int id;
  final String name;
  final String fullName;
  final String? description;
  final String htmlUrl;
  final String? language;
  final int stars;
  final int forks;
  final bool isPrivate;
  final DateTime? updatedAt;

  const GitHubRepo({
    required this.id,
    required this.name,
    required this.fullName,
    this.description,
    required this.htmlUrl,
    this.language,
    this.stars = 0,
    this.forks = 0,
    this.isPrivate = false,
    this.updatedAt,
  });

  factory GitHubRepo.fromMap(Map<String, dynamic> map) {
    return GitHubRepo(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      fullName: map['full_name'] ?? '',
      description: map['description'],
      htmlUrl: map['html_url'] ?? '',
      language: map['language'],
      stars: map['stargazers_count'] ?? 0,
      forks: map['forks_count'] ?? 0,
      isPrivate: map['private'] ?? false,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'])
          : null,
    );
  }
}

class GitHubUserStats {
  final String username;
  final String? name;
  final String? avatarUrl;
  final String? bio;
  final int totalRepos;
  final int followers;
  final int following;
  final int totalStars;
  final int totalForks;
  final String? topLanguage;
  final Map<String, int> languages;
  final List<GitHubRepo> repos;

  const GitHubUserStats({
    required this.username,
    this.name,
    this.avatarUrl,
    this.bio,
    this.totalRepos = 0,
    this.followers = 0,
    this.following = 0,
    this.totalStars = 0,
    this.totalForks = 0,
    this.topLanguage,
    this.languages = const {},
    this.repos = const [],
  });

  factory GitHubUserStats.fromMap(Map<String, dynamic> map) {
    final profile = map['profile'] as Map<String, dynamic>;
    final reposList = (map['repos'] as List? ?? [])
        .map((r) => GitHubRepo.fromMap(r))
        .toList();
    final langs = Map<String, int>.from(map['languages'] ?? {});

    return GitHubUserStats(
      username: profile['login'] ?? '',
      name: profile['name'],
      avatarUrl: profile['avatar_url'],
      bio: profile['bio'],
      totalRepos: map['total_repos'] ?? 0,
      followers: map['followers'] ?? 0,
      following: map['following'] ?? 0,
      totalStars: map['total_stars'] ?? 0,
      totalForks: map['total_forks'] ?? 0,
      topLanguage: map['top_language'],
      languages: langs,
      repos: reposList,
    );
  }
}

// =====================
// GitHub File Model
// =====================
class GitHubFile {
  final String name;
  final String path;
  final String type; // 'file' or 'dir'
  final int? size;
  final String? downloadUrl;
  final String sha;

  const GitHubFile({
    required this.name,
    required this.path,
    required this.type,
    this.size,
    this.downloadUrl,
    required this.sha,
  });

  bool get isDirectory => type == 'dir';
  bool get isFile => type == 'file';

  String get extension {
    final dot = name.lastIndexOf('.');
    if (dot == -1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  String get icon {
    if (isDirectory) return '📁';
    switch (extension) {
      case 'dart': return '🎯';
      case 'py': return '🐍';
      case 'js': case 'ts': return '📜';
      case 'jsx': case 'tsx': return '⚛️';
      case 'swift': return '🍎';
      case 'kt': return '🟣';
      case 'java': return '☕';
      case 'go': return '🐹';
      case 'rs': return '🦀';
      case 'cpp': case 'c': return '⚙️';
      case 'cs': return '💙';
      case 'rb': return '💎';
      case 'php': return '🐘';
      case 'html': return '🌐';
      case 'css': return '🎨';
      case 'json': return '📋';
      case 'yaml': case 'yml': return '⚙️';
      case 'md': return '📝';
      case 'sh': case 'bash': return '💻';
      case 'sql': return '🗄️';
      case 'png': case 'jpg': case 'jpeg': case 'gif': case 'svg': return '🖼️';
      case 'pdf': return '📄';
      case 'zip': case 'tar': case 'gz': return '📦';
      default: return '📄';
    }
  }

  factory GitHubFile.fromMap(Map<String, dynamic> map) {
    return GitHubFile(
      name: map['name'] as String? ?? '',
      path: map['path'] as String? ?? '',
      type: map['type'] as String? ?? 'file',
      size: map['size'] as int?,
      downloadUrl: map['download_url'] as String?,
      sha: map['sha'] as String? ?? '',
    );
  }

  String get formattedSize {
    if (size == null) return '';
    if (size! < 1024) return '${size}B';
    if (size! < 1024 * 1024) return '${(size! / 1024).toStringAsFixed(1)}KB';
    return '${(size! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}