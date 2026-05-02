class DeveloperProfile {
  final String uid;
  final String name;
  final String email;
  final String? photoURL;
  final String? bio;
  final String? specialization;
  final String experienceLevel;
  final List<String> techSkills;
  final String? location;
  final String? website;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DeveloperProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.photoURL,
    this.bio,
    this.specialization,
    this.experienceLevel = 'Junior (0-2 years)',
    this.techSkills = const [],
    this.location,
    this.website,
    this.createdAt,
    this.updatedAt,
  });

  factory DeveloperProfile.fromMap(Map<String, dynamic> map, String uid) {
    return DeveloperProfile(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoURL: map['photoURL'],
      bio: map['bio'],
      specialization: map['specialization'],
      experienceLevel: map['experienceLevel'] ?? 'Junior (0-2 years)',
      techSkills: List<String>.from(map['techSkills'] ?? []),
      location: map['location'],
      website: map['website'],
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
      'name': name,
      'email': email,
      'photoURL': photoURL,
      'bio': bio,
      'specialization': specialization,
      'experienceLevel': experienceLevel,
      'techSkills': techSkills,
      'location': location,
      'website': website,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  DeveloperProfile copyWith({
    String? name,
    String? email,
    String? photoURL,
    String? bio,
    String? specialization,
    String? experienceLevel,
    List<String>? techSkills,
    String? location,
    String? website,
  }) {
    return DeveloperProfile(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      specialization: specialization ?? this.specialization,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      techSkills: techSkills ?? this.techSkills,
      location: location ?? this.location,
      website: website ?? this.website,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class DeveloperSkill {
  final String id;
  final String name;
  final String category;
  final int proficiency; // 1-5
  final DateTime? addedAt;

  const DeveloperSkill({
    required this.id,
    required this.name,
    required this.category,
    this.proficiency = 3,
    this.addedAt,
  });

  factory DeveloperSkill.fromMap(Map<String, dynamic> map, String id) {
    return DeveloperSkill(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? 'Other',
      proficiency: map['proficiency'] ?? 3,
      addedAt: map['addedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['addedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'proficiency': proficiency,
      'addedAt': addedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
    };
  }
}

class Certificate {
  final String id;
  final String title;
  final String issuer;
  final String? description;
  final String? credentialUrl;
  final DateTime? issuedDate;
  final DateTime? expiryDate;

  const Certificate({
    required this.id,
    required this.title,
    required this.issuer,
    this.description,
    this.credentialUrl,
    this.issuedDate,
    this.expiryDate,
  });

  factory Certificate.fromMap(Map<String, dynamic> map, String id) {
    return Certificate(
      id: id,
      title: map['title'] ?? '',
      issuer: map['issuer'] ?? '',
      description: map['description'],
      credentialUrl: map['credentialUrl'],
      issuedDate: map['issuedDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['issuedDate'])
          : null,
      expiryDate: map['expiryDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expiryDate'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'issuer': issuer,
      'description': description,
      'credentialUrl': credentialUrl,
      'issuedDate': issuedDate?.millisecondsSinceEpoch,
      'expiryDate': expiryDate?.millisecondsSinceEpoch,
    };
  }
}

class DeveloperLink {
  final String id;
  final String type;
  final String label;
  final String url;

  const DeveloperLink({
    required this.id,
    required this.type,
    required this.label,
    required this.url,
  });

  factory DeveloperLink.fromMap(Map<String, dynamic> map, String id) {
    return DeveloperLink(
      id: id,
      type: map['type'] ?? 'other',
      label: map['label'] ?? '',
      url: map['url'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'label': label,
      'url': url,
    };
  }
}
