import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, LinearGradient;
import 'package:provider/provider.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';
import '../theme/app_theme.dart';
import '../components/bottom_nav_bar.dart';
import 'dart:ui' as ui;

class AchievementsScreen extends StatefulWidget {
  final Function(int)? onSwitchTab;
  final int? currentIndex;

  const AchievementsScreen({
    Key? key,
    this.onSwitchTab,
    this.currentIndex,
  }) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _gridAnimationController;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievementService = Provider.of<AchievementService>(context);
    final userId = Provider.of<String?>(context);

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

          Column(
            children: [
              // Custom navigation bar with neon effect
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                  vertical: AppTheme.spacingM,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark.withOpacity(0.9),
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
                child: SafeArea(
                  bottom: false,
                  child: Text(
                    'Achievements',
                    style: AppTheme.headingLarge.copyWith(
                      color: AppTheme.surfaceLight,
                      shadows: [
                        Shadow(
                          color: AppTheme.primaryNeon.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Main content
              Expanded(
                child: userId == null
                    ? _buildSignInPrompt()
                    : _buildAchievementsList(achievementService, userId),
              ),

              // Bottom Navigation Bar
              if (widget.onSwitchTab != null && widget.currentIndex != null)
                BottomNavBar(
                  onSwitchTab: widget.onSwitchTab!,
                  currentIndex: widget.currentIndex!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignInPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              color: AppTheme.primaryNeon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              border: Border.all(
                color: AppTheme.primaryNeon.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: AppTheme.neonShadow(AppTheme.primaryNeon),
            ),
            child: Icon(
              CupertinoIcons.person_crop_circle,
              size: 64,
              color: AppTheme.primaryNeon,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            'Please sign in to view achievements',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.surfaceLight,
              shadows: [
                Shadow(
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

  Widget _buildAchievementsList(AchievementService achievementService, String userId) {
    return StreamBuilder<List<Achievement>>(
      stream: achievementService.getAchievements(),
      builder: (context, achievementsSnapshot) {
        if (achievementsSnapshot.hasError) {
          return _buildErrorState(() {
            achievementService.initializeDefaultAchievements();
          });
        }

        if (!achievementsSnapshot.hasData) {
          return const Center(child: CupertinoActivityIndicator());
        }

        final achievements = achievementsSnapshot.data!;

        return StreamBuilder<List<UserAchievement>>(
          stream: achievementService.getUserAchievements(userId),
          builder: (context, userAchievementsSnapshot) {
            final userAchievements = userAchievementsSnapshot.data ?? [];

            return CustomScrollView(
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () async {
                    // The streams will automatically refresh the data
                  },
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final achievement = achievements[index];
                        final userAchievement = userAchievements.firstWhere(
                          (ua) => ua.achievementId == achievement.id,
                          orElse: () => UserAchievement(
                            userId: userId,
                            achievementId: achievement.id,
                            earnedAt: DateTime.now(),
                            progress: 0,
                          ),
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.spacingL),
                          child: _AchievementCard(
                            achievement: achievement,
                            userAchievement: userAchievement,
                          ),
                        );
                      },
                      childCount: achievements.length,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState(VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              border: Border.all(
                color: AppTheme.primaryTeal.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: AppTheme.neonShadow(AppTheme.primaryTeal),
            ),
            child: Icon(
              CupertinoIcons.wifi_slash,
              size: 64,
              color: AppTheme.primaryTeal,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            'Unable to load achievements',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.surfaceLight,
              shadows: [
                Shadow(
                  color: AppTheme.primaryTeal.withOpacity(0.5),
                  blurRadius: 5,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Please check your internet connection',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingL,
                vertical: AppTheme.spacingM,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                border: Border.all(
                  color: AppTheme.primaryTeal,
                  width: 2,
                ),
                boxShadow: AppTheme.neonShadow(AppTheme.primaryTeal),
              ),
              child: Text(
                'Try Again',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.primaryTeal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final UserAchievement userAchievement;

  const _AchievementCard({
    required this.achievement,
    required this.userAchievement,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = userAchievement.isCompleted;
    final progress = userAchievement.progress;
    final target = achievement.requirements['target'] as int? ?? 100;
    final progressPercentage = (progress / target).clamp(0.0, 1.0);
    final color = isCompleted ? AppTheme.primaryNeon : AppTheme.primaryTeal;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.8),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: AppTheme.neonShadow(color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(
                    color: color.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Icon(
                  CupertinoIcons.star_fill,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.name,
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.surfaceLight,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      achievement.description,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.surfaceLight.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: AppTheme.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(
                      color: color.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '${achievement.points} pts',
                    style: AppTheme.bodyMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (!isCompleted) ...[
            const SizedBox(height: AppTheme.spacingL),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.surfaceLight.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      '$progress / $target',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.surfaceLight.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingS),
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXS),
                    color: color.withOpacity(0.1),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: progressPercentage,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXS),
                        color: color,
                        boxShadow: AppTheme.neonShadow(color),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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

    // Draw vertical lines
    for (double x = offset; x <= size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = offset; y <= size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CyberpunkGridPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
} 