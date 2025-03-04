import 'package:flutter/cupertino.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import '../services/project_service.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class ProjectType {
  final String name;
  final String description;
  final IconData icon;

  const ProjectType({
    required this.name,
    required this.description,
    required this.icon,
  });
}

class NewProjectScreen extends StatefulWidget {
  const NewProjectScreen({Key? key}) : super(key: key);

  @override
  State<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends State<NewProjectScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isProcessing = false;
  String _spokenText = '';
  ProjectType? _selectedType;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  final List<ProjectType> _projectTypes = [
    ProjectType(
      name: 'Essay',
      description: 'Academic essays, research papers, or analytical writing',
      icon: CupertinoIcons.doc_text,
    ),
    ProjectType(
      name: 'Story',
      description: 'Creative writing, short stories, or narratives',
      icon: CupertinoIcons.book,
    ),
    ProjectType(
      name: 'Report',
      description: 'Lab reports, book reports, or project documentation',
      icon: CupertinoIcons.chart_bar_square,
    ),
    ProjectType(
      name: 'Speech',
      description: 'Presentations, debates, or public speaking scripts',
      icon: CupertinoIcons.mic,
    ),
    ProjectType(
      name: 'Journal',
      description: 'Personal reflections, learning journals, or diaries',
      icon: CupertinoIcons.pencil_circle,
    ),
    ProjectType(
      name: 'Social Media',
      description: 'Engaging posts, threads, and social media content',
      icon: CupertinoIcons.chat_bubble_2,
    ),
  ];

  Future<void> _createProject() async {
    if (_selectedType == null) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Select Project Type'),
          content: const Text('Please select a project type before continuing.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      // Check if title and description are not empty
      if (_titleController.text.trim().isEmpty) {
        throw Exception('Please enter a project title');
      }

      if (_descriptionController.text.trim().isEmpty) {
        throw Exception('Please enter a project description');
      }

      final projectService = Provider.of<ProjectService>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Check if user is authenticated
      if (!authProvider.isAuthenticated) {
        throw Exception('Please sign in to create a project');
      }

      await projectService.createProject(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType!.name,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundDark,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.surfaceDark.withOpacity(0.9),
        middle: Text(
          'New Project',
          style: AppTheme.headingMedium.copyWith(
            color: AppTheme.primaryNeon,
            shadows: AppTheme.neonShadow(AppTheme.primaryNeon),
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text(
            'Cancel',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.primaryTeal,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Animated background grid
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: GridPainter(
                      progress: _animation.value,
                      primaryColor: AppTheme.primaryNeon.withOpacity(0.1),
                      secondaryColor: AppTheme.primaryTeal.withOpacity(0.05),
                    ),
                  );
                },
              ),
            ),
            // Content
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                children: [
                  // Project Type Selection
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      border: Border.all(
                        color: AppTheme.primaryNeon.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: AppTheme.neonShadow(AppTheme.primaryNeon),
                    ),
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Project Type',
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.primaryNeon,
                            shadows: AppTheme.neonShadow(AppTheme.primaryNeon),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        Wrap(
                          spacing: AppTheme.spacingS,
                          runSpacing: AppTheme.spacingS,
                          children: _projectTypes.map((type) => GestureDetector(
                            onTap: () => setState(() => _selectedType = type),
                            child: Container(
                              width: (MediaQuery.of(context).size.width - AppTheme.spacingL * 4) / 2,
                              padding: const EdgeInsets.all(AppTheme.spacingM),
                              decoration: BoxDecoration(
                                color: _selectedType == type
                                    ? AppTheme.primaryNeon.withOpacity(0.1)
                                    : AppTheme.backgroundDark.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                                border: Border.all(
                                  color: _selectedType == type
                                      ? AppTheme.primaryNeon
                                      : AppTheme.primaryNeon.withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: _selectedType == type
                                    ? AppTheme.neonShadow(AppTheme.primaryNeon)
                                    : null,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    type.icon,
                                    color: _selectedType == type
                                        ? AppTheme.primaryNeon
                                        : AppTheme.surfaceLight.withOpacity(0.7),
                                    size: 32,
                                  ),
                                  const SizedBox(height: AppTheme.spacingS),
                                  Text(
                                    type.name,
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: _selectedType == type
                                          ? AppTheme.primaryNeon
                                          : AppTheme.surfaceLight,
                                      fontWeight: FontWeight.bold,
                                      shadows: _selectedType == type
                                          ? AppTheme.neonShadow(AppTheme.primaryNeon)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spacingXS),
                                  Text(
                                    type.description,
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.surfaceLight.withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingXL),

                  // Project Details Section
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      border: Border.all(
                        color: AppTheme.primaryTeal.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: AppTheme.neonShadow(AppTheme.primaryTeal),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Project Details',
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.primaryTeal,
                            shadows: AppTheme.neonShadow(AppTheme.primaryTeal),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        CupertinoTextField(
                          controller: _titleController,
                          placeholder: 'Project Title',
                          padding: const EdgeInsets.all(AppTheme.spacingM),
                          style: AppTheme.bodyMedium.copyWith(
                            color: CupertinoColors.black,
                          ),
                          placeholderStyle: AppTheme.bodyMedium.copyWith(
                            color: CupertinoColors.systemGrey,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            border: Border.all(
                              color: AppTheme.primaryTeal.withOpacity(0.3),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        CupertinoTextField(
                          controller: _descriptionController,
                          placeholder: 'Project Description',
                          padding: const EdgeInsets.all(AppTheme.spacingM),
                          style: AppTheme.bodyMedium.copyWith(
                            color: CupertinoColors.black,
                          ),
                          placeholderStyle: AppTheme.bodyMedium.copyWith(
                            color: CupertinoColors.systemGrey,
                          ),
                          maxLines: 4,
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            border: Border.all(
                              color: AppTheme.primaryTeal.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingXL),

                  // Create Button
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingM,
                    ),
                    onPressed: _isProcessing ? null : _createProject,
                    color: AppTheme.primaryNeon,
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isProcessing
                          ? const CupertinoActivityIndicator(color: AppTheme.surfaceLight)
                          : Text(
                              'Create Project',
                              style: AppTheme.bodyLarge.copyWith(
                                color: AppTheme.surfaceLight,
                                shadows: AppTheme.neonShadow(AppTheme.surfaceLight),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  GridPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 30.0;
    final verticalLines = (size.width / spacing).ceil();
    final horizontalLines = (size.height / spacing).ceil();

    // Draw vertical lines
    for (var i = 0; i <= verticalLines; i++) {
      final x = i * spacing;
      final opacity = (1 - (x / size.width)).clamp(0.0, 1.0);
      paint.color = primaryColor.withOpacity(opacity * (1 - progress));
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (var i = 0; i <= horizontalLines; i++) {
      final y = i * spacing;
      final opacity = (1 - (y / size.height)).clamp(0.0, 1.0);
      paint.color = secondaryColor.withOpacity(opacity * progress);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      primaryColor != oldDelegate.primaryColor ||
      secondaryColor != oldDelegate.secondaryColor;
} 