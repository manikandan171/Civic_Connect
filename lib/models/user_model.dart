class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final DateTime createdAt;
  final bool isGuest;
  final int points;
  final int issuesReported;
  final int issuesResolved;
  final String preferredLanguage;
  final bool notificationsEnabled;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    required this.createdAt,
    this.isGuest = false,
    this.points = 0,
    this.issuesReported = 0,
    this.issuesResolved = 0,
    this.preferredLanguage = 'en',
    this.notificationsEnabled = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profileImage: json['profileImage'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isGuest: json['isGuest'] ?? false,
      points: json['points'] ?? 0,
      issuesReported: json['issuesReported'] ?? 0,
      issuesResolved: json['issuesResolved'] ?? 0,
      preferredLanguage: json['preferredLanguage'] ?? 'en',
      notificationsEnabled: json['notificationsEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
      'isGuest': isGuest,
      'points': points,
      'issuesReported': issuesReported,
      'issuesResolved': issuesResolved,
      'preferredLanguage': preferredLanguage,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    DateTime? createdAt,
    bool? isGuest,
    int? points,
    int? issuesReported,
    int? issuesResolved,
    String? preferredLanguage,
    bool? notificationsEnabled,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      isGuest: isGuest ?? this.isGuest,
      points: points ?? this.points,
      issuesReported: issuesReported ?? this.issuesReported,
      issuesResolved: issuesResolved ?? this.issuesResolved,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, phone: $phone, isGuest: $isGuest, points: $points)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
