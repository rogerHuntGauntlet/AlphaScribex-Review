import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, LinearGradient;
import '../theme/app_theme.dart';
import '../screens/new_project_screen.dart';
import '../navigation/bottom_nav_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:math' show pi;
import 'dart:ui' as ui;
import '../components/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onSwitchTab;
  final int currentIndex;

  const HomeScreen({
    Key? key,
    required this.onSwitchTab,
    required this.currentIndex,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _gridAnimationController;
  final ScrollController _mapScrollController = ScrollController();
  
  // Track current selected layer (0: Mechanics, 1: Sequencing, 2: Voice)
  int _selectedLayer = 0;
  
  @override
  void initState() {
    super.initState();
    _gridAnimationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _gridAnimationController.dispose();
    _mapScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Writer';

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundDark,
      child: Stack(
        children: [
          // Animated cyberpunk grid background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _gridAnimationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: CyberpunkGridPainter(
                    animation: _gridAnimationController.value,
                  ),
                );
              },
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top bar with profile and stats
                _buildTopBar(displayName),
                
                // Layer selection tabs
                _buildLayerTabs(),
                
                // Main scrollable content (level map)
                Expanded(
                  child: _buildLevelMap(),
                ),
                
                // Bottom navigation
                _buildBottomNavigation(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(String displayName) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppTheme.radiusXL),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNeon.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile section
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingXS),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryNeon,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryNeon.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              CupertinoIcons.person_fill,
              color: AppTheme.primaryNeon,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          
          // Name and level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTheme.headingMedium.copyWith(
                    color: AppTheme.surfaceLight,
                    shadows: [
                      Shadow(
                        color: AppTheme.primaryNeon.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                _buildProgressBar(),
              ],
            ),
          ),
          
          // Stats button
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              // TODO: Show stats overlay
            },
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: AppTheme.primaryNeon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Icon(
                CupertinoIcons.chart_bar_fill,
                color: AppTheme.primaryNeon,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Row(
        children: [
          Container(
            width: 100, // TODO: Calculate based on actual progress
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryNeon,
                  AppTheme.primaryNeon.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryNeon.withOpacity(0.5),
                  blurRadius: 5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerTabs() {
    final layers = ['Mechanics', 'Sequencing', 'Voice'];
    final colors = [AppTheme.primaryNeon, AppTheme.primaryTeal, AppTheme.primaryLavender];

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      child: Row(
        children: List.generate(
          layers.length,
          (index) => Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() => _selectedLayer = index);
              },
              child: Container(
                margin: const EdgeInsets.all(AppTheme.spacingXS),
                decoration: BoxDecoration(
                  color: _selectedLayer == index
                      ? colors[index].withOpacity(0.2)
                      : AppTheme.surfaceDark.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  border: Border.all(
                    color: _selectedLayer == index
                        ? colors[index]
                        : colors[index].withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: _selectedLayer == index
                      ? [
                          BoxShadow(
                            color: colors[index].withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    layers[index],
                    style: AppTheme.bodyMedium.copyWith(
                      color: _selectedLayer == index
                          ? colors[index]
                          : colors[index].withOpacity(0.5),
                      fontWeight: _selectedLayer == index
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelMap() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: CustomScrollView(
          controller: _mapScrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Level nodes will be generated here based on the selected layer
                  ..._buildLevelNodes(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLevelNodes() {
    // This would normally come from a data source
    final levels = [
      {'level': 1, 'name': 'Basic Sentence Structure', 'completed': true},
      {'level': 2, 'name': 'Grammar Fundamentals', 'completed': true},
      {'level': 3, 'name': 'Advanced Punctuation', 'completed': false},
      {'level': 4, 'name': 'Complex Sentences', 'completed': false},
      {'level': 5, 'name': 'Writing Style', 'locked': true},
    ];

    return levels.map((level) => _buildLevelNode(level)).toList();
  }

  Widget _buildLevelNode(Map<String, dynamic> level) {
    final bool isLocked = level['locked'] ?? false;
    final bool isCompleted = level['completed'] ?? false;
    final color = isLocked
        ? AppTheme.textSecondary
        : isCompleted
            ? AppTheme.primaryNeon
            : AppTheme.primaryTeal;

    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: AppTheme.spacingM,
      ),
      child: GestureDetector(
        onTap: isLocked ? null : () {
          HapticFeedback.mediumImpact();
          // TODO: Navigate to level
        },
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Row(
            children: [
              // Level number with glow effect
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                  border: Border.all(
                    color: color.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    level['level'].toString(),
                    style: AppTheme.headingMedium.copyWith(
                      color: color,
                      shadows: [
                        Shadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level['name'],
                      style: AppTheme.bodyLarge.copyWith(
                        color: isLocked
                            ? AppTheme.textSecondary
                            : AppTheme.surfaceLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isLocked) ...[
                      const SizedBox(height: AppTheme.spacingXS),
                      _buildProgressBar(), // Reuse progress bar component
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Icon(
                isLocked
                    ? CupertinoIcons.lock_fill
                    : isCompleted
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.chevron_right,
                color: color,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavBar(
      onSwitchTab: widget.onSwitchTab,
      currentIndex: widget.currentIndex,
    );
  }
}

class CyberpunkGridPainter extends CustomPainter {
  final double animation;

  CyberpunkGridPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryNeon.withOpacity(0.1)
      ..strokeWidth = 1;

    final spacing = 30.0;
    final offset = animation * spacing;

    // Draw animated vertical lines
    for (double x = -spacing + offset; x < size.width + spacing; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * 0.2, size.height),
        paint,
      );
    }

    // Draw horizontal lines with fade effect
    for (double y = 0; y < size.height; y += spacing) {
      paint.color = AppTheme.primaryNeon.withOpacity(
        0.1 * (1 - y / size.height),
      );
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CyberpunkGridPainter oldDelegate) =>
      animation != oldDelegate.animation;
} 