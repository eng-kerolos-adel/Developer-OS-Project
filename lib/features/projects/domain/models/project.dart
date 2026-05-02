class Project {
  final String id;
  final String uid;
  final String name;
  final String description;
  final List<String> techStack;
  final String projectType;
  final String targetPlatform;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? githubUrl;
  final String? demoUrl;
  final List<ProjectWeek> roadmap;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Project({
    required this.id,
    required this.uid,
    required this.name,
    required this.description,
    required this.techStack,
    required this.projectType,
    required this.targetPlatform,
    this.status = 'planning',
    this.startDate,
    this.endDate,
    this.githubUrl,
    this.demoUrl,
    this.roadmap = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Project.fromMap(Map<String, dynamic> map, String id) {
    return Project(
      id: id,
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      techStack: List<String>.from(map['techStack'] ?? []),
      projectType: map['projectType'] ?? '',
      targetPlatform: map['targetPlatform'] ?? '',
      status: map['status'] ?? 'planning',
      startDate: map['startDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startDate'])
          : null,
      endDate: map['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endDate'])
          : null,
      githubUrl: map['githubUrl'],
      demoUrl: map['demoUrl'],
      roadmap: (map['roadmap'] as List? ?? [])
          .map((w) => ProjectWeek.fromMap(w))
          .toList(),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'description': description,
      'techStack': techStack,
      'projectType': projectType,
      'targetPlatform': targetPlatform,
      'status': status,
      'startDate': startDate?.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'githubUrl': githubUrl,
      'demoUrl': demoUrl,
      'roadmap': roadmap.map((w) => w.toMap()).toList(),
      'createdAt': createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Project copyWith({
    String? name,
    String? description,
    List<String>? techStack,
    String? projectType,
    String? targetPlatform,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? githubUrl,
    String? demoUrl,
    List<ProjectWeek>? roadmap,
  }) {
    return Project(
      id: id,
      uid: uid,
      name: name ?? this.name,
      description: description ?? this.description,
      techStack: techStack ?? this.techStack,
      projectType: projectType ?? this.projectType,
      targetPlatform: targetPlatform ?? this.targetPlatform,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      githubUrl: githubUrl ?? this.githubUrl,
      demoUrl: demoUrl ?? this.demoUrl,
      roadmap: roadmap ?? this.roadmap,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  int get completionPercentage {
    if (roadmap.isEmpty) return 0;
    final completed = roadmap.where((w) => w.completed).length;
    return ((completed / roadmap.length) * 100).round();
  }
}

class ProjectWeek {
  final int weekNumber;
  final String title;
  final String description;
  final List<String> tasks;
  final bool completed;

  const ProjectWeek({
    required this.weekNumber,
    required this.title,
    required this.description,
    required this.tasks,
    this.completed = false,
  });

  factory ProjectWeek.fromMap(Map<String, dynamic> map) {
    return ProjectWeek(
      weekNumber: map['weekNumber'] ?? 1,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      tasks: List<String>.from(map['tasks'] ?? []),
      completed: map['completed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weekNumber': weekNumber,
      'title': title,
      'description': description,
      'tasks': tasks,
      'completed': completed,
    };
  }

  ProjectWeek copyWith({bool? completed}) {
    return ProjectWeek(
      weekNumber: weekNumber,
      title: title,
      description: description,
      tasks: tasks,
      completed: completed ?? this.completed,
    );
  }
}

class ProjectTask {
  final String id;
  final String projectId;
  final String uid;
  final String title;
  final String? description;
  final String status; // todo, in_progress, done
  final String priority; // low, medium, high
  final DateTime? dueDate;
  final DateTime? createdAt;

  const ProjectTask({
    required this.id,
    required this.projectId,
    required this.uid,
    required this.title,
    this.description,
    this.status = 'todo',
    this.priority = 'medium',
    this.dueDate,
    this.createdAt,
  });

  factory ProjectTask.fromMap(Map<String, dynamic> map, String id) {
    return ProjectTask(
      id: id,
      projectId: map['projectId'] ?? '',
      uid: map['uid'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      status: map['status'] ?? 'todo',
      priority: map['priority'] ?? 'medium',
      dueDate: map['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'uid': uid,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'createdAt': createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  ProjectTask copyWith({String? status, String? title, String? description, String? priority}) {
    return ProjectTask(
      id: id,
      projectId: projectId,
      uid: uid,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate,
      createdAt: createdAt,
    );
  }
}
