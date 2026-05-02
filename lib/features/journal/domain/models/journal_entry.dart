class JournalEntry {
  final String id;
  final String uid;
  final String content;
  final List<String> tags;
  final String mood; // 'great', 'good', 'okay', 'bad'
  final int productivityScore; // 1-5
  final DateTime date;
  final DateTime createdAt;

  const JournalEntry({
    required this.id,
    required this.uid,
    required this.content,
    this.tags = const [],
    this.mood = 'good',
    this.productivityScore = 3,
    required this.date,
    required this.createdAt,
  });

  factory JournalEntry.fromMap(Map<String, dynamic> map, String id) {
    return JournalEntry(
      id: id,
      uid: map['uid'] ?? '',
      content: map['content'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      mood: map['mood'] ?? 'good',
      productivityScore: map['productivityScore'] ?? 3,
      date: map['date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['date'])
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'content': content,
        'tags': tags,
        'mood': mood,
        'productivityScore': productivityScore,
        'date': date.millisecondsSinceEpoch,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  String get moodEmoji {
    switch (mood) {
      case 'great':
        return '🚀';
      case 'good':
        return '😊';
      case 'okay':
        return '😐';
      case 'bad':
        return '😔';
      default:
        return '😊';
    }
  }

  String get productivityLabel {
    switch (productivityScore) {
      case 5:
        return 'Extremely Productive';
      case 4:
        return 'Very Productive';
      case 3:
        return 'Productive';
      case 2:
        return 'Somewhat Productive';
      case 1:
        return 'Low Productivity';
      default:
        return 'Productive';
    }
  }
}