import 'package:flutter/cupertino.dart';
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

class _NewProjectScreenState extends State<NewProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isProcessing = false;
  ProjectType? _selectedType;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      
      if (title.isEmpty) {
        throw Exception('Please enter a project title');
      }

      if (description.isEmpty) {
        throw Exception('Please enter a project description');
      }

      final projectService = Provider.of<ProjectService>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (!authProvider.isAuthenticated) {
        throw Exception('Please sign in to create a project');
      }

      await projectService.createProject(
        title: title,
        description: description,
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
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        middle: Text(
          'New Project',
          style: AppTheme.headingMedium.copyWith(
            color: CupertinoColors.white,
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
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Project Type Selection
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: CupertinoColors.black,
                        border: Border.all(
                          color: CupertinoColors.systemGrey,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Project Type',
                            style: AppTheme.bodyLarge.copyWith(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _projectTypes.map((type) => GestureDetector(
                              onTap: () => setState(() => _selectedType = type),
                              child: Container(
                                width: (MediaQuery.of(context).size.width - 64) / 2,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _selectedType == type
                                      ? AppTheme.primaryTeal.withOpacity(0.2)
                                      : CupertinoColors.black,
                                  border: Border.all(
                                    color: _selectedType == type
                                        ? AppTheme.primaryTeal
                                        : CupertinoColors.systemGrey,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      type.icon,
                                      color: _selectedType == type
                                          ? AppTheme.primaryTeal
                                          : CupertinoColors.systemGrey,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      type.name,
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: _selectedType == type
                                            ? CupertinoColors.white
                                            : CupertinoColors.systemGrey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      type.description,
                                      style: AppTheme.bodySmall.copyWith(
                                        color: CupertinoColors.systemGrey,
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

                    const SizedBox(height: 24),

                    // Project Details Section
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: CupertinoColors.black,
                        border: Border.all(
                          color: CupertinoColors.systemGrey,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project Details',
                            style: AppTheme.bodyLarge.copyWith(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CupertinoTextField(
                            controller: _titleController,
                            placeholder: 'Project Title',
                            padding: const EdgeInsets.all(12),
                            style: AppTheme.bodyMedium.copyWith(
                              color: CupertinoColors.white,
                            ),
                            placeholderStyle: AppTheme.bodyMedium.copyWith(
                              color: CupertinoColors.systemGrey,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.black,
                              border: Border.all(
                                color: CupertinoColors.systemGrey,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 16),
                          CupertinoTextField(
                            controller: _descriptionController,
                            placeholder: 'Project Description',
                            padding: const EdgeInsets.all(12),
                            style: AppTheme.bodyMedium.copyWith(
                              color: CupertinoColors.white,
                            ),
                            placeholderStyle: AppTheme.bodyMedium.copyWith(
                              color: CupertinoColors.systemGrey,
                            ),
                            maxLines: 4,
                            decoration: BoxDecoration(
                              color: CupertinoColors.black,
                              border: Border.all(
                                color: CupertinoColors.systemGrey,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Create Button
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      onPressed: _isProcessing ? null : _createProject,
                      color: AppTheme.primaryTeal,
                      borderRadius: BorderRadius.circular(8),
                      child: _isProcessing
                          ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                          : Text(
                              'Create Project',
                              style: AppTheme.bodyLarge.copyWith(
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 