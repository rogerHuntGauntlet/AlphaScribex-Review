import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, LinearGradient;
import 'package:provider/provider.dart';
import '../services/project_service.dart';
import '../models/writing_project.dart';
import '../theme/app_theme.dart';
import '../navigation/bottom_nav_config.dart';
import 'new_project_screen.dart';
import 'writing_editor_screen.dart';
import 'dart:ui' as ui;
import '../components/bottom_nav_bar.dart';

class ProjectListScreen extends StatefulWidget {
  final Function(int) onSwitchTab;
  final int currentIndex;

  const ProjectListScreen({
    Key? key,
    required this.onSwitchTab,
    required this.currentIndex,
  }) : super(key: key);

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> with SingleTickerProviderStateMixin {
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

  void _showNewProjectScreen(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const NewProjectScreen(),
      ),
    );
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
          
          // Main content
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
                  child: Row(
                    children: [
                      Text(
                        'Projects',
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
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showNewProjectScreen(context),
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spacingS),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            border: Border.all(
                              color: AppTheme.primaryTeal.withOpacity(0.5),
                              width: 2,
                            ),
                            boxShadow: AppTheme.neonShadow(AppTheme.primaryTeal),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.add,
                                color: AppTheme.primaryTeal,
                                size: 20,
                              ),
                              const SizedBox(width: AppTheme.spacingXS),
                              Text(
                                'New Project',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.primaryTeal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Project list with stream builder
              Expanded(
                child: StreamBuilder<List<WritingProject>>(
                  stream: Provider.of<ProjectService>(context).getUserProjects(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error.toString());
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState();
                    }

                    final projects = snapshot.data ?? [];

                    if (projects.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildProjectList(projects);
                  },
                ),
              ),

              // Bottom Navigation Bar
              BottomNavBar(
                onSwitchTab: widget.onSwitchTab,
                currentIndex: widget.currentIndex,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = widget.currentIndex == index;
    return GestureDetector(
      onTap: () => widget.onSwitchTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryNeon.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: isSelected ? AppTheme.primaryNeon : Colors.transparent,
            width: 1,
          ),
          boxShadow: isSelected ? AppTheme.neonShadow(AppTheme.primaryNeon) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryNeon : AppTheme.surfaceLight.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: isSelected ? AppTheme.primaryNeon : AppTheme.surfaceLight.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        margin: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withOpacity(0.8),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: AppTheme.primaryPink.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: AppTheme.neonShadow(AppTheme.primaryPink),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: AppTheme.primaryPink,
              size: 48,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'Error Loading Projects',
              style: AppTheme.headingMedium.copyWith(
                color: AppTheme.primaryPink,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              error,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.surfaceLight.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CupertinoActivityIndicator(
            radius: 20,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'Loading Projects...',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.surfaceLight.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            // Refresh will happen automatically with StreamBuilder
          },
        ),
        SliverFillRemaining(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              margin: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark.withOpacity(0.8),
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                border: Border.all(
                  color: AppTheme.primaryTeal.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: AppTheme.neonShadow(AppTheme.primaryTeal),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.doc_text,
                    size: 64,
                    color: AppTheme.primaryTeal,
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  Text(
                    'No Projects Yet',
                    style: AppTheme.headingMedium.copyWith(
                      color: AppTheme.surfaceLight,
                      shadows: [
                        Shadow(
                          color: AppTheme.primaryTeal.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'Start your writing journey by creating your first project',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.surfaceLight.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  GestureDetector(
                    onTap: () => _showNewProjectScreen(context),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.add,
                            color: AppTheme.primaryTeal,
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Text(
                            'Create New Project',
                            style: AppTheme.bodyLarge.copyWith(
                              color: AppTheme.primaryTeal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectList(List<WritingProject> projects) {
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            // Refresh will happen automatically with StreamBuilder
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final project = projects[index];
                return _ProjectCard(project: project);
              },
              childCount: projects.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final WritingProject project;

  const _ProjectCard({required this.project});

  Widget _buildProgressIndicator(WritingProject project) {
    if (project.lastAnalysis == null) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingS,
          vertical: AppTheme.spacingXS,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          border: Border.all(
            color: AppTheme.textSecondary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.doc_text,
              size: 14,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: AppTheme.spacingXS),
            Text(
              'Not analyzed',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final currentLevel = project.lastAnalysis!['currentLevel'] as int? ?? 0;
    final progress = project.lastAnalysis!['progress'] as String? ?? '';
    final isPerfect = (project.lastAnalysis![
      currentLevel == 0 ? 'sentenceAnalysis' :
      currentLevel == 1 ? 'paragraphAnalysis' :
      'pageAnalysis'
    ] as List<dynamic>? ?? []).every((item) => item['isPerfect'] == true);

    // Extract just the numbers from progress (e.g., "2/5" from "2/5 sentences achieved")
    final progressNumbers = progress.split(' ').first;
    final levelType = currentLevel == 0 ? 'sentences' :
                     currentLevel == 1 ? 'paragraphs' :
                     'pages';

    final color = isPerfect ? AppTheme.primaryNeon : AppTheme.primaryTeal;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: AppTheme.neonShadow(color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPerfect ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.arrow_right_circle_fill,
            size: 14,
            color: color,
          ),
          const SizedBox(width: AppTheme.spacingXS),
          Flexible(
            child: Text(
              '$progressNumbers $levelType',
              style: AppTheme.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => WritingEditorScreen(project: project),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withOpacity(0.8),
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(
            color: AppTheme.primaryNeon.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: AppTheme.neonShadow(AppTheme.primaryNeon),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and chevron
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      project.title,
                      style: AppTheme.headingMedium.copyWith(
                        color: AppTheme.surfaceLight,
                        shadows: [
                          Shadow(
                            color: AppTheme.primaryNeon.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: AppTheme.spacingS),
                    child: Icon(
                      CupertinoIcons.chevron_right,
                      color: AppTheme.primaryNeon,
                    ),
                  ),
                ],
              ),
            ),

            // Description if available
            if (project.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                ),
                child: Text(
                  project.description,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.surfaceLight.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Stats bar
            Container(
              margin: const EdgeInsets.all(AppTheme.spacingL),
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                border: Border.all(
                  color: AppTheme.primaryNeon.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Word count and progress in a row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Word count
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingS,
                          vertical: AppTheme.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLavender.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          border: Border.all(
                            color: AppTheme.primaryLavender.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.text_alignleft,
                              size: 14,
                              color: AppTheme.primaryLavender,
                            ),
                            const SizedBox(width: AppTheme.spacingXS),
                            Text(
                              '${project.wordCount} words',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.primaryLavender,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      // Progress indicator
                      Container(
                        constraints: const BoxConstraints(minWidth: 120),
                        child: _buildProgressIndicator(project),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Additional stats could go here
                ],
              ),
            ),
          ],
        ),
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
      ..color = AppTheme.primaryTeal.withOpacity(0.1)
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
      paint.color = AppTheme.primaryTeal.withOpacity(
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