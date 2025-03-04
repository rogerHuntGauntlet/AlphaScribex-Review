import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, LinearGradient;
import '../theme/app_theme.dart';
import '../components/bottom_nav_bar.dart';
import 'dart:ui' as ui;

class ExercisesScreen extends StatefulWidget {
  final Function(int)? onSwitchTab;
  final int? currentIndex;

  const ExercisesScreen({
    Key? key,
    this.onSwitchTab,
    this.currentIndex,
  }) : super(key: key);

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> with SingleTickerProviderStateMixin {
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
                      color: AppTheme.primaryTeal.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Text(
                    'Writing Exercises',
                    style: AppTheme.headingLarge.copyWith(
                      color: AppTheme.surfaceLight,
                      shadows: [
                        Shadow(
                          color: AppTheme.primaryTeal.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Main content
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    CupertinoSliverRefreshControl(
                      onRefresh: () async {
                        // TODO: Implement refresh logic
                      },
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCategoryCard(
                              'Fundamentals',
                              'Master the basics of writing',
                              AppTheme.primaryTeal,
                              [
                                _Exercise(
                                  'Sentence Structure',
                                  'Learn to write clear and effective sentences',
                                  0.8,
                                ),
                                _Exercise(
                                  'Grammar Essentials',
                                  'Review key grammar rules and concepts',
                                  0.6,
                                ),
                                _Exercise(
                                  'Punctuation',
                                  'Use punctuation marks correctly',
                                  0.4,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacingL),
                            _buildCategoryCard(
                              'Paragraphs',
                              'Build strong paragraphs',
                              AppTheme.primaryNeon,
                              [
                                _Exercise(
                                  'Topic Sentences',
                                  'Write effective topic sentences',
                                  0.7,
                                ),
                                _Exercise(
                                  'Supporting Details',
                                  'Add relevant details and examples',
                                  0.5,
                                ),
                                _Exercise(
                                  'Transitions',
                                  'Connect ideas smoothly',
                                  0.3,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacingL),
                            _buildCategoryCard(
                              'Essays',
                              'Plan and write essays',
                              AppTheme.primaryLavender,
                              [
                                _Exercise(
                                  'Essay Structure',
                                  'Learn the parts of an essay',
                                  0.4,
                                ),
                                _Exercise(
                                  'Thesis Statements',
                                  'Write clear thesis statements',
                                  0.2,
                                ),
                                _Exercise(
                                  'Conclusions',
                                  'Write strong conclusions',
                                  0.0,
                                  isLocked: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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

  Widget _buildCategoryCard(
    String title,
    String description,
    Color color,
    List<_Exercise> exercises,
  ) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(
                      color: color.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.book_fill,
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
                        title,
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.surfaceLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        description,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...exercises.map((exercise) => _buildExerciseItem(exercise, color)),
        ],
      ),
    );
  }

  Widget _buildExerciseItem(_Exercise exercise, Color color) {
    return Column(
      children: [
        Container(
          height: 1,
          color: color.withOpacity(0.1),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: exercise.isLocked ? null : () {
            // TODO: Navigate to exercise
          },
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingS),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(
                      color: exercise.isLocked
                          ? AppTheme.textSecondary.withOpacity(0.3)
                          : color.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    exercise.isLocked
                        ? CupertinoIcons.lock_fill
                        : CupertinoIcons.doc_text_fill,
                    color: exercise.isLocked
                        ? AppTheme.textSecondary
                        : color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.title,
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: exercise.isLocked
                              ? AppTheme.textSecondary
                              : AppTheme.surfaceLight,
                        ),
                      ),
                      if (!exercise.isLocked) ...[
                        const SizedBox(height: AppTheme.spacingXS),
                        Text(
                          exercise.description,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (exercise.progress > 0) ...[
                          const SizedBox(height: AppTheme.spacingS),
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppTheme.radiusXS),
                              color: color.withOpacity(0.1),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: exercise.progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusXS),
                                  color: color,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: exercise.isLocked
                      ? AppTheme.textSecondary
                      : color,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Exercise {
  final String title;
  final String description;
  final double progress;
  final bool isLocked;

  const _Exercise(
    this.title,
    this.description,
    this.progress, {
    this.isLocked = false,
  });
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