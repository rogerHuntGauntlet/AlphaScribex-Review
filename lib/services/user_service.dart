import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfile {
  final String displayName;
  final String? bio;
  final String? photoUrl;

  UserProfile({
    required this.displayName,
    this.bio,
    this.photoUrl,
  });
}

class UserStats {
  final int totalWords;
  final int projectCount;
  final int currentStreak;

  UserStats({
    required this.totalWords,
    required this.projectCount,
    required this.currentStreak,
  });
}

class UserGoals {
  final int dailyWordCount;
  final int dailyWordGoal;
  final int weeklyProjectCount;
  final int weeklyProjectGoal;

  UserGoals({
    required this.dailyWordCount,
    required this.dailyWordGoal,
    required this.weeklyProjectCount,
    required this.weeklyProjectGoal,
  });
}

class UserService {
  final FirebaseFirestore _firestore;
  final String _userId;

  UserService(this._firestore, this._userId);

  Stream<UserProfile> get userProfileStream {
    return _firestore
        .collection('users')
        .doc(_userId)
        .snapshots()
        .map((doc) => UserProfile(
              displayName: doc.data()?['displayName'] ?? 'Writer',
              bio: doc.data()?['bio'],
              photoUrl: doc.data()?['photoUrl'],
            ));
  }

  Stream<UserStats> get userStatsStream {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('stats')
        .doc('writing')
        .snapshots()
        .map((doc) => UserStats(
              totalWords: doc.data()?['totalWords'] ?? 0,
              projectCount: doc.data()?['projectCount'] ?? 0,
              currentStreak: doc.data()?['currentStreak'] ?? 0,
            ));
  }

  Stream<UserGoals> get userGoalsStream {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('goals')
        .doc('writing')
        .snapshots()
        .map((doc) => UserGoals(
              dailyWordCount: doc.data()?['dailyWordCount'] ?? 0,
              dailyWordGoal: doc.data()?['dailyWordGoal'] ?? 1000,
              weeklyProjectCount: doc.data()?['weeklyProjectCount'] ?? 0,
              weeklyProjectGoal: doc.data()?['weeklyProjectGoal'] ?? 3,
            ));
  }

  Stream<List<String>> get favoriteBooksStream {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('books')
        .doc('favorites')
        .snapshots()
        .map((doc) => List<String>.from(doc.data()?['books'] ?? []));
  }

  Future<void> addFavoriteBook(String book) async {
    final docRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('books')
        .doc('favorites');

    await _firestore.runTransaction((transaction) async {
      final docSnapshot = await transaction.get(docRef);
      
      if (!docSnapshot.exists) {
        transaction.set(docRef, {
          'books': [book],
        });
      } else {
        final books = List<String>.from(docSnapshot.data()?['books'] ?? []);
        if (!books.contains(book)) {
          books.add(book);
          transaction.update(docRef, {
            'books': books,
          });
        }
      }
    });
  }

  Future<void> removeFavoriteBook(String book) async {
    final docRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('books')
        .doc('favorites');

    await _firestore.runTransaction((transaction) async {
      final docSnapshot = await transaction.get(docRef);
      
      if (docSnapshot.exists) {
        final books = List<String>.from(docSnapshot.data()?['books'] ?? []);
        books.remove(book);
        transaction.update(docRef, {
          'books': books,
        });
      }
    });
  }

  Future<void> refreshUserData() async {
    // Refresh user data from the server
    // This will trigger the streams to update
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{};
    
    if (displayName != null) updates['displayName'] = displayName;
    if (bio != null) updates['bio'] = bio;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    
    if (updates.isNotEmpty) {
      await _firestore
          .collection('users')
          .doc(_userId)
          .update(updates);
    }
  }
} 