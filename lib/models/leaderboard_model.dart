class LeaderboardEntry {
  final int rank;
  final String userId;
  final String userName;
  final String? userAvatar;
  final int points;
  final int issuesReported;
  final int issuesResolved;
  final List<String> badges;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.points,
    required this.issuesReported,
    required this.issuesResolved,
    required this.badges,
    required this.isCurrentUser,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] ?? 0,
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userAvatar: json['userAvatar'],
      points: json['points'] ?? 0,
      issuesReported: json['issuesReported'] ?? 0,
      issuesResolved: json['issuesResolved'] ?? 0,
      badges: List<String>.from(json['badges'] ?? []),
      isCurrentUser: json['isCurrentUser'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'points': points,
      'issuesReported': issuesReported,
      'issuesResolved': issuesResolved,
      'badges': badges,
      'isCurrentUser': isCurrentUser,
    };
  }

  LeaderboardEntry copyWith({
    int? rank,
    String? userId,
    String? userName,
    String? userAvatar,
    int? points,
    int? issuesReported,
    int? issuesResolved,
    List<String>? badges,
    bool? isCurrentUser,
  }) {
    return LeaderboardEntry(
      rank: rank ?? this.rank,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      points: points ?? this.points,
      issuesReported: issuesReported ?? this.issuesReported,
      issuesResolved: issuesResolved ?? this.issuesResolved,
      badges: badges ?? this.badges,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  @override
  String toString() {
    return 'LeaderboardEntry(rank: $rank, userName: $userName, points: $points)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaderboardEntry && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
