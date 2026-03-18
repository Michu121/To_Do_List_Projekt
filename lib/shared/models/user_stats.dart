class UserStats {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final int points;
  final int tasksCreated;
  final int tasksCompleted;
  final int groupsJoined;

  const UserStats({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.points = 0,
    this.tasksCreated = 0,
    this.tasksCompleted = 0,
    this.groupsJoined = 0,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      uid: json['uid'] as String? ?? '',
      displayName: json['name'] as String? ?? json['displayName'] as String? ?? 'User',
      photoUrl: json['photo'] as String? ?? json['photoUrl'] as String?,
      points: (json['points'] as num?)?.toInt() ?? 0,
      tasksCreated: (json['tasksCreated'] as num?)?.toInt() ?? 0,
      tasksCompleted: (json['tasksCompleted'] as num?)?.toInt() ?? 0,
      groupsJoined: (json['groupsJoined'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'points': points,
      'tasksCreated': tasksCreated,
      'tasksCompleted': tasksCompleted,
      'groupsJoined': groupsJoined,
    };
  }

  static String rankTitle(int points) {
    if (points >= 500) return '🏆 Legend';
    if (points >= 200) return '⭐ Expert';
    if (points >= 100) return '🔥 Pro';
    if (points >= 50) return '📈 Rising';
    if (points >= 20) return '🌱 Beginner';
    return '🆕 Newcomer';
  }
}