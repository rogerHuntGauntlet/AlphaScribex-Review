import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../services/achievement_service.dart';
import '../services/initialization_service.dart';
import 'project_list_screen.dart';
import 'achievements_screen.dart';
import 'home_screen.dart';
import 'exercises_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late InitializationService _initializationService;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializationService = InitializationService(
      Provider.of<AchievementService>(context, listen: false),
    );
    _initialize();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initialize() async {
    await _initializationService.initializeIfNeeded();
  }

  void switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            key: const PageStorageKey('home'),
            onSwitchTab: switchToTab,
            currentIndex: _currentIndex,
          ),
          ProjectListScreen(
            key: const PageStorageKey('projects'),
            onSwitchTab: switchToTab,
            currentIndex: _currentIndex,
          ),
          ExercisesScreen(
            key: const PageStorageKey('exercises'),
            onSwitchTab: switchToTab,
            currentIndex: _currentIndex,
          ),
          AchievementsScreen(
            key: const PageStorageKey('achievements'),
            onSwitchTab: switchToTab,
            currentIndex: _currentIndex,
          ),
          ProfileScreen(
            key: const PageStorageKey('profile'),
            onSwitchTab: switchToTab,
            currentIndex: _currentIndex,
          ),
        ],
      ),
    );
  }
}