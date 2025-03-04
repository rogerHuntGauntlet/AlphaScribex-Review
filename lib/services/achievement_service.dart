import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/achievement.dart';
import '../models/writing_project.dart';

class AchievementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _achievementsCollection = 'achievements';
  final String _userAchievementsCollection = 'user_achievements';

  // Initialize default achievements only if they don't exist
  Future<void> initializeDefaultAchievements() async {
    // Check if achievements already exist
    final existingAchievements = await _firestore
        .collection(_achievementsCollection)
        .limit(1)
        .get();

    if (existingAchievements.docs.isNotEmpty) {
      return; // Achievements already initialized
    }

    final defaultAchievements = [
      {
        'name': 'Level 1',
        'description': 'Write 5 perfect sentences',
        'points': 100,
        'level': 1,
        'category': 'writing',
        'requirements': {
          'type': 'perfect_sentences',
          'target': 5,
        },
      },
      {
        'name': 'Level 2',
        'description': 'Write 5 perfect paragraphs',
        'points': 200,
        'level': 2,
        'category': 'writing',
        'requirements': {
          'type': 'perfect_paragraphs',
          'target': 5,
        },
      },
      {
        'name': 'Level 3',
        'description': 'Write 5 perfect pages',
        'points': 300,
        'level': 3,
        'category': 'writing',
        'requirements': {
          'type': 'perfect_pages',
          'target': 5,
        },
      },
    ];

    try {
      final batch = _firestore.batch();

      for (var achievement in defaultAchievements) {
        final doc = _firestore.collection(_achievementsCollection).doc();
        batch.set(doc, {
          'id': doc.id,
          ...achievement,
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error initializing achievements: $e');
      // Handle the error appropriately
    }
  }

  // Get all achievements
  Stream<List<Achievement>> getAchievements() {
    return _firestore
        .collection(_achievementsCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Achievement.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Get user's achievements
  Stream<List<UserAchievement>> getUserAchievements(String userId) {
    return _firestore
        .collection(_userAchievementsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserAchievement.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Check and update achievements based on writing project
  Future<void> checkProjectAchievements(WritingProject project) async {
    final achievements = await _firestore
        .collection(_achievementsCollection)
        .where('category', isEqualTo: 'writing')
        .get();

    for (var doc in achievements.docs) {
      final achievement = Achievement.fromMap(doc.data());
      await _checkAchievement(project.userId, achievement, project);
    }
  }

  // Check individual achievement progress
  Future<void> _checkAchievement(
    String userId,
    Achievement achievement,
    WritingProject project,
  ) async {
    final userAchievementDoc = await _firestore
        .collection(_userAchievementsCollection)
        .where('userId', isEqualTo: userId)
        .where('achievementId', isEqualTo: achievement.id)
        .get();

    if (userAchievementDoc.docs.isNotEmpty &&
        userAchievementDoc.docs.first.data()['isCompleted']) {
      return; // Achievement already completed
    }

    int progress = await _calculateProgress(userId, achievement, project);
    bool isCompleted = progress >= (achievement.requirements['target'] ?? 0);

    if (userAchievementDoc.docs.isEmpty) {
      // Create new user achievement
      await _firestore.collection(_userAchievementsCollection).add({
        'userId': userId,
        'achievementId': achievement.id,
        'earnedAt': isCompleted ? DateTime.now() : null,
        'progress': progress,
        'isCompleted': isCompleted,
      });
    } else {
      // Update existing user achievement
      await userAchievementDoc.docs.first.reference.update({
        'progress': progress,
        'isCompleted': isCompleted,
        if (isCompleted && userAchievementDoc.docs.first.data()['earnedAt'] == null)
          'earnedAt': DateTime.now(),
      });
    }
  }

  // Calculate progress for an achievement
  Future<int> _calculateProgress(
    String userId,
    Achievement achievement,
    WritingProject project,
  ) async {
    switch (achievement.requirements['type']) {
      case 'project_count':
        return await _getProjectCount(userId);
      case 'word_count':
        final content = await _getLatestContent(project.id);
        return _getWordCount(content ?? []);
      case 'streak_days':
        return await _getWritingStreak(userId);
      default:
        return 0;
    }
  }

  Future<List<dynamic>?> _getLatestContent(String projectId) async {
    final latestVersion = await _firestore
        .collection('project_versions')
        .where('projectId', isEqualTo: projectId)
        .orderBy('versionNumber', descending: true)
        .limit(1)
        .get();

    if (latestVersion.docs.isEmpty) return null;
    return latestVersion.docs.first.data()['content'] as List<dynamic>;
  }

  // Helper methods for progress calculation
  Future<int> _getProjectCount(String userId) async {
    final projects = await _firestore
        .collection('writing_projects')
        .where('userId', isEqualTo: userId)
        .get();
    return projects.docs.length;
  }

  int _getWordCount(List<dynamic> content) {
    // Parse the Quill Delta content to extract text
    String text = '';
    for (var operation in content) {
      if (operation['insert'] is String) {
        text += operation['insert'] as String;
      }
    }
    
    // Count words (split by whitespace and filter empty strings)
    return text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  Future<int> _getWritingStreak(String userId) async {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));

    final projects = await _firestore
        .collection('writing_projects')
        .where('userId', isEqualTo: userId)
        .where('updatedAt', isGreaterThanOrEqualTo: oneWeekAgo)
        .orderBy('updatedAt', descending: true)
        .get();

    if (projects.docs.isEmpty) return 0;

    int streak = 1;
    DateTime lastDate = (projects.docs.first.data()['updatedAt'] as Timestamp).toDate();

    for (var i = 1; i < projects.docs.length; i++) {
      final currentDate = (projects.docs[i].data()['updatedAt'] as Timestamp).toDate();
      final difference = lastDate.difference(currentDate).inDays;

      if (difference == 1) {
        streak++;
        lastDate = currentDate;
      } else if (difference > 1) {
        break;
      }
    }

    return streak;
  }

  Future<void> updateAchievementProgress(String userId, WritingProject project) async {
    // Get the latest version content
    final latestVersion = await _firestore
        .collection('project_versions')
        .where('projectId', isEqualTo: project.id)
        .orderBy('versionNumber', descending: true)
        .limit(1)
        .get();

    if (latestVersion.docs.isEmpty) return;

    final content = latestVersion.docs.first.data()['content'] as List<dynamic>;
    final wordCount = _getWordCount(content);

    // Update word count achievements
    final wordCountAchievements = await _firestore
        .collection('achievements')
        .where('type', isEqualTo: 'word_count')
        .get();

    for (var achievement in wordCountAchievements.docs) {
      final target = achievement.data()['requirements']['target'] as int;
      
      // Check if user already has this achievement
      final userAchievement = await _firestore
          .collection('user_achievements')
          .where('userId', isEqualTo: userId)
          .where('achievementId', isEqualTo: achievement.id)
          .limit(1)
          .get();

      if (userAchievement.docs.isEmpty) {
        // Create new user achievement
        await _firestore.collection('user_achievements').add({
          'userId': userId,
          'achievementId': achievement.id,
          'progress': wordCount,
          'isCompleted': wordCount >= target,
          'earnedAt': wordCount >= target ? FieldValue.serverTimestamp() : null,
        });
      } else {
        // Update existing achievement
        final doc = userAchievement.docs.first;
        if (!doc.data()['isCompleted']) {
          await doc.reference.update({
            'progress': wordCount,
            'isCompleted': wordCount >= target,
            'earnedAt': wordCount >= target ? FieldValue.serverTimestamp() : null,
          });
        }
      }
    }
  }

  // Get user's level based on completed achievements
  Future<String> getUserLevel(String userId) async {
    final userAchievements = await _firestore
        .collection(_userAchievementsCollection)
        .where('userId', isEqualTo: userId)
        .where('isCompleted', isEqualTo: true)
        .get();

    if (userAchievements.docs.isEmpty) {
      return 'Level 0: Beginner';
    }

    // Find the highest level achievement completed
    int highestLevel = 0;
    for (var doc in userAchievements.docs) {
      final achievementDoc = await _firestore
          .collection(_achievementsCollection)
          .doc(doc.data()['achievementId'])
          .get();
      
      if (achievementDoc.exists) {
        final level = achievementDoc.data()?['level'] ?? 0;
        if (level > highestLevel) {
          highestLevel = level;
        }
      }
    }

    switch (highestLevel) {
      case 3:
        return 'Level 3: Page Master';
      case 2:
        return 'Level 2: Paragraph Pro';
      case 1:
        return 'Level 1: Sentence Sage';
      default:
        return 'Level 0: Beginner';
    }
  }
} 