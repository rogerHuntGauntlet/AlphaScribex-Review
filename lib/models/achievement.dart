import 'package:cloud_firestore/cloud_firestore.dart';

class Achievement {
  final String id;
  final String name;
  final String description;
  final int points;
  final String badgeUrl;
  final String category;
  final Map<String, dynamic> requirements;
  final bool isSecret;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.points,
    required this.badgeUrl,
    required this.category,
    required this.requirements,
    this.isSecret = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'points': points,
      'badgeUrl': badgeUrl,
      'category': category,
      'requirements': requirements,
      'isSecret': isSecret,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      points: map['points'] ?? 0,
      badgeUrl: map['badgeUrl'] ?? '',
      category: map['category'] ?? '',
      requirements: map['requirements'] ?? {},
      isSecret: map['isSecret'] ?? false,
    );
  }

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement.fromMap(json);
}

class UserAchievement {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime earnedAt;
  final int progress;
  final bool isCompleted;

  UserAchievement({
    required this.userId,
    required this.achievementId,
    required this.earnedAt,
    this.id = '',
    this.progress = 0,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'achievementId': achievementId,
      'earnedAt': earnedAt,
      'progress': progress,
      'isCompleted': isCompleted,
    };
  }

  factory UserAchievement.fromMap(Map<String, dynamic> map) {
    return UserAchievement(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      achievementId: map['achievementId'] ?? '',
      earnedAt: (map['earnedAt'] as Timestamp).toDate(),
      progress: map['progress'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  factory UserAchievement.fromJson(Map<String, dynamic> json) => UserAchievement.fromMap(json);
} 