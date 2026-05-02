// =====================
// Models
// =====================

class InterviewApplication {
  final String id;
  final String uid;
  final String company;
  final String position;
  final String status;
  final DateTime appliedDate;
  final String? jobUrl;
  final String? notes;
  final List<String> completedTopics;
  final int? salaryMin;
  final int? salaryMax;

  const InterviewApplication({
    required this.id,
    required this.uid,
    required this.company,
    required this.position,
    this.status = 'applied',
    required this.appliedDate,
    this.jobUrl,
    this.notes,
    this.completedTopics = const [],
    this.salaryMin,
    this.salaryMax,
  });

  static const List<String> statuses = [
    'applied', 'screening', 'interview', 'offer', 'rejected', 'withdrawn'
  ];

  static String statusEmoji(String status) {
    switch (status) {
      case 'applied': return '📨';
      case 'screening': return '📞';
      case 'interview': return '🎯';
      case 'offer': return '🎉';
      case 'rejected': return '❌';
      case 'withdrawn': return '🚪';
      default: return '📨';
    }
  }

  factory InterviewApplication.fromMap(Map<String, dynamic> map, String id) {
    return InterviewApplication(
      id: id,
      uid: map['uid'] ?? '',
      company: map['company'] ?? '',
      position: map['position'] ?? '',
      status: map['status'] ?? 'applied',
      appliedDate: map['appliedDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['appliedDate'])
          : DateTime.now(),
      jobUrl: map['jobUrl'],
      notes: map['notes'],
      completedTopics: List<String>.from(map['completedTopics'] ?? []),
      salaryMin: map['salaryMin'],
      salaryMax: map['salaryMax'],
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'company': company,
        'position': position,
        'status': status,
        'appliedDate': appliedDate.millisecondsSinceEpoch,
        'jobUrl': jobUrl,
        'notes': notes,
        'completedTopics': completedTopics,
        'salaryMin': salaryMin,
        'salaryMax': salaryMax,
      };

  InterviewApplication copyWith({String? status, String? notes, List<String>? completedTopics}) {
    return InterviewApplication(
      id: id, uid: uid, company: company, position: position,
      status: status ?? this.status,
      appliedDate: appliedDate,
      jobUrl: jobUrl,
      notes: notes ?? this.notes,
      completedTopics: completedTopics ?? this.completedTopics,
      salaryMin: salaryMin, salaryMax: salaryMax,
    );
  }
}

class DSAProblem {
  final String id;
  final String uid;
  final String title;
  final String difficulty;
  final String category;
  final bool isSolved;
  final String? notes;
  final String? leetcodeUrl;
  final DateTime? solvedAt;

  const DSAProblem({
    required this.id,
    required this.uid,
    required this.title,
    required this.difficulty,
    required this.category,
    this.isSolved = false,
    this.notes,
    this.leetcodeUrl,
    this.solvedAt,
  });

  static const List<String> categories = [
    'Array', 'String', 'LinkedList', 'Tree', 'Graph',
    'DP', 'Sorting', 'Searching', 'Hash Table',
    'Stack', 'Queue', 'Heap', 'Trie', 'Math',
  ];

  factory DSAProblem.fromMap(Map<String, dynamic> map, String id) {
    return DSAProblem(
      id: id,
      uid: map['uid'] ?? '',
      title: map['title'] ?? '',
      difficulty: map['difficulty'] ?? 'medium',
      category: map['category'] ?? 'Array',
      isSolved: map['isSolved'] ?? false,
      notes: map['notes'],
      leetcodeUrl: map['leetcodeUrl'],
      solvedAt: map['solvedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['solvedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'title': title,
        'difficulty': difficulty,
        'category': category,
        'isSolved': isSolved,
        'notes': notes,
        'leetcodeUrl': leetcodeUrl,
        'solvedAt': solvedAt?.millisecondsSinceEpoch,
      };

  DSAProblem copyWith({bool? isSolved, DateTime? solvedAt}) => DSAProblem(
        id: id, uid: uid, title: title, difficulty: difficulty,
        category: category,
        isSolved: isSolved ?? this.isSolved,
        notes: notes, leetcodeUrl: leetcodeUrl,
        solvedAt: solvedAt ?? this.solvedAt,
      );
}