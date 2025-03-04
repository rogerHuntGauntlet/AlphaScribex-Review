import 'package:firebase_auth/firebase_auth.dart';
import 'achievement_service.dart';

class InitializationService {
  final AchievementService _achievementService;
  final FirebaseAuth _auth;
  bool _initialized = false;

  InitializationService(this._achievementService) : _auth = FirebaseAuth.instance;

  Future<void> initializeIfNeeded() async {
    if (_initialized) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _achievementService.initializeDefaultAchievements();
      _initialized = true;
    } catch (e) {
      print('Error during initialization: $e');
      // Handle initialization error appropriately
    }
  }
} 