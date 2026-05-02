class CodeSnippet {
  final String id;
  final String uid;
  final String title;
  final String code;
  final String language;
  final List<String> tags;
  final bool isFavorite;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CodeSnippet({
    required this.id,
    required this.uid,
    required this.title,
    required this.code,
    required this.language,
    this.tags = const [],
    this.isFavorite = false,
    this.description,
    required this.createdAt,
    this.updatedAt,
  });

  factory CodeSnippet.fromMap(Map<String, dynamic> map, String id) {
    return CodeSnippet(
      id: id,
      uid: map['uid'] ?? '',
      title: map['title'] ?? '',
      code: map['code'] ?? '',
      language: map['language'] ?? 'dart',
      tags: List<String>.from(map['tags'] ?? []),
      isFavorite: map['isFavorite'] ?? false,
      description: map['description'],
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'title': title,
        'code': code,
        'language': language,
        'tags': tags,
        'isFavorite': isFavorite,
        'description': description,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

  CodeSnippet copyWith({bool? isFavorite}) => CodeSnippet(
        id: id,
        uid: uid,
        title: title,
        code: code,
        language: language,
        tags: tags,
        isFavorite: isFavorite ?? this.isFavorite,
        description: description,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  static const List<String> supportedLanguages = [
    'dart', 'python', 'javascript', 'typescript',
    'kotlin', 'swift', 'java', 'go', 'rust',
    'cpp', 'c', 'csharp', 'php', 'ruby',
    'bash', 'sql', 'yaml', 'json', 'xml',
    'html', 'css', 'markdown',
  ];
}