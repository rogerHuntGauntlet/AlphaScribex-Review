import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:provider/provider.dart';
import '../models/writing_project.dart';
import '../services/writing_project_service.dart';
import '../services/achievement_service.dart';
import '../theme/app_theme.dart';
import '../services/ai_analysis_service.dart';
import '../config/api_config.dart';

class WritingEditorScreen extends StatefulWidget {
  final WritingProject project;

  const WritingEditorScreen({
    Key? key,
    required this.project,
  }) : super(key: key);

  @override
  State<WritingEditorScreen> createState() => _WritingEditorScreenState();
}

class _WritingEditorScreenState extends State<WritingEditorScreen> with SingleTickerProviderStateMixin {
  final WritingProjectService _projectService = WritingProjectService();
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = true;
  bool _isAnalyzing = false;
  Timer? _autoSaveTimer;
  String _achievementLevel = '';
  final AIAnalysisService _aiService = AIAnalysisService(APIConfig.openAIKey);
  final Map<String, bool> _expandedItems = {};
  List<Map<String, dynamic>> _analysisData = [];
  String _progressText = '';
  String _nextSteps = '';
  
  // Animation controller for the background grid
  AnimationController? _gridAnimationController;

  // Add this field to track loading state for each sentence
  final Map<String, bool> _loadingExamples = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimationController();
    _loadContent();
    _loadAchievementLevel();
    _loadLastAnalysis();
    // Set up auto-save timer
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) => _saveContent());
  }

  void _initializeAnimationController() {
    _gridAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _textController.dispose();
    _autoSaveTimer?.cancel();
    _gridAnimationController?.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    try {
      final content = await _projectService.getProjectContent(widget.project.id);
      if (content != null) {
        _textController.text = content.toString();
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to load content: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _saveContent() async {
    try {
      await _projectService.saveProjectContent(
        widget.project.id,
        _textController.text,
      );
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to save content: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _loadAchievementLevel() async {
    try {
      final achievementService = Provider.of<AchievementService>(context, listen: false);
      final userId = Provider.of<String?>(context, listen: false);
      if (userId != null) {
        final level = await achievementService.getUserLevel(userId);
        if (mounted) {
          setState(() {
            _achievementLevel = level;
          });
        }
      }
    } catch (e) {
      print('Error loading achievement level: $e');
      if (mounted) {
        setState(() {
          _achievementLevel = 'Level 0: Beginner';
        });
      }
    }
  }

  Future<void> _loadLastAnalysis() async {
    try {
      final results = await _projectService.getAnalysisResults(widget.project.id);
      if (results != null && mounted) {
        setState(() {
          _progressText = results['progress'] ?? '';
          _nextSteps = results['nextSteps'] ?? '';
          
          final analysisKey = results['currentLevel'] == 0 ? 'sentenceAnalysis' :
                             results['currentLevel'] == 1 ? 'paragraphAnalysis' :
                             'pageAnalysis';
          
          _analysisData = (results[analysisKey] as List<dynamic>? ?? [])
              .map((item) => item as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (e) {
      print('Error loading last analysis: $e');
    }
  }

  Future<void> _analyzeAndShowResults() async {
    if (_textController.text.trim().isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: const Text('Please write some text before submitting.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisData = [];
      _progressText = '';
      _nextSteps = '';
    });

    try {
      // Get current level
      int currentLevel = 0;
      try {
        currentLevel = int.parse(_achievementLevel.split(':')[0].replaceAll('Level ', '').trim());
      } catch (e) {
        print('Error parsing level: $e');
        currentLevel = 0;
      }

      // Analyze text
      final analysis = await _aiService.analyzeText(_textController.text, currentLevel);
      
      if (mounted) {
        // Save content first
        await _saveContent();
        
        if (analysis.containsKey('error')) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Analysis Error'),
              content: Text(analysis['error'] ?? 'Unknown error occurred'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
          return;
        }
        
        // Add current level to analysis results
        final resultsToSave = {
          ...analysis,
          'currentLevel': currentLevel,
        };
        
        // Save analysis results
        await _projectService.saveAnalysisResults(widget.project.id, resultsToSave);
        
        // Update the analysis results
        setState(() {
          _progressText = analysis['progress'] ?? 'No progress data';
          _nextSteps = analysis['nextSteps'] ?? 'Continue improving your writing';
          
          switch (currentLevel) {
            case 0:
              _analysisData = (analysis['sentenceAnalysis'] as List<dynamic>? ?? [])
                  .map((item) => item as Map<String, dynamic>)
                  .toList();
              break;
            case 1:
              _analysisData = (analysis['paragraphAnalysis'] as List<dynamic>? ?? [])
                  .map((item) => item as Map<String, dynamic>)
                  .toList();
              break;
            case 2:
              _analysisData = (analysis['pageAnalysis'] as List<dynamic>? ?? [])
                  .map((item) => item as Map<String, dynamic>)
                  .toList();
              break;
          }
        });
      }
    } catch (e) {
      print('Analysis error: $e');
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to analyze text: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _showExamples(String text) async {
    setState(() => _loadingExamples[text] = true);
    
    try {
      final examples = await _aiService.getSimilarExamples(text);
      
      if (mounted) {
        showCupertinoModalPopup(
          context: context,
          builder: (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusXL),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Similar Examples',
                      style: AppTheme.headingMedium.copyWith(
                        color: CupertinoColors.white,
                        shadows: AppTheme.neonShadow(AppTheme.primaryLavender),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: AppTheme.primaryLavender,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacingL),
                Text(
                  'Your sentence:',
                  style: AppTheme.bodyMedium.copyWith(
                    color: CupertinoColors.white.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: AppTheme.spacingS),
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(
                      color: AppTheme.primaryLavender.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    text,
                    style: AppTheme.bodyMedium.copyWith(
                      color: CupertinoColors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                SizedBox(height: AppTheme.spacingL),
                Text(
                  'Similar sentences by famous writers:',
                  style: AppTheme.bodyMedium.copyWith(
                    color: CupertinoColors.white.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: AppTheme.spacingM),
                Expanded(
                  child: ListView.builder(
                    itemCount: examples.length,
                    itemBuilder: (context, index) {
                      final example = examples[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: AppTheme.spacingM),
                        padding: EdgeInsets.all(AppTheme.spacingM),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          border: Border.all(
                            color: AppTheme.primaryNeon.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              example['text'],
                              style: AppTheme.bodyMedium.copyWith(
                                color: CupertinoColors.white,
                              ),
                            ),
                            SizedBox(height: AppTheme.spacingS),
                            Text(
                              '— ${example['author']}',
                              style: AppTheme.bodySmall.copyWith(
                                color: CupertinoColors.white.withOpacity(0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            if (example['work'] != null) ...[
                              SizedBox(height: AppTheme.spacingXS),
                              Text(
                                'from "${example['work']}"',
                                style: AppTheme.bodySmall.copyWith(
                                  color: CupertinoColors.white.withOpacity(0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            if (example['similarity'] != null) ...[
                              SizedBox(height: AppTheme.spacingM),
                              Container(
                                padding: EdgeInsets.all(AppTheme.spacingS),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLavender.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                  border: Border.all(
                                    color: AppTheme.primaryLavender.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  example['similarity'],
                                  style: AppTheme.bodySmall.copyWith(
                                    color: CupertinoColors.white.withOpacity(0.9),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to fetch examples: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingExamples[text] = false);
      }
    }
  }

  Widget _buildAnalysisItem(String text, int score, bool isPerfect, String feedback, String suggestions) {
    final isExpanded = _expandedItems[text] ?? false;
    final color = isPerfect ? AppTheme.primaryNeon : AppTheme.primaryTeal;
    final isLoading = _loadingExamples[text] ?? false;
    
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingM),
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
          GestureDetector(
            onTap: () => setState(() => _expandedItems[text] = !isExpanded),
            child: Container(
              padding: EdgeInsets.all(AppTheme.spacingL),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text,
                          style: AppTheme.bodyLarge.copyWith(
                            color: color,
                            shadows: AppTheme.neonShadow(color),
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingS),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingS,
                                vertical: AppTheme.spacingXS,
                              ),
                              decoration: BoxDecoration(
                                color: _getScoreColor(score).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                border: Border.all(
                                  color: _getScoreColor(score).withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Score: $score/10',
                                style: AppTheme.bodySmall.copyWith(
                                  color: _getScoreColor(score),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: AppTheme.spacingS),
                            if (isPerfect)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingS,
                                  vertical: AppTheme.spacingXS,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryNeon.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                  border: Border.all(
                                    color: AppTheme.primaryNeon.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      CupertinoIcons.star_fill,
                                      size: 12,
                                      color: AppTheme.primaryNeon,
                                    ),
                                    SizedBox(width: AppTheme.spacingXS),
                                    Text(
                                      'Perfect!',
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.primaryNeon,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    color: color,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: EdgeInsets.all(AppTheme.spacingL).copyWith(top: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    color: color.withOpacity(0.2),
                    height: AppTheme.spacingL,
                  ),
                  Text(
                    'Feedback:',
                    style: AppTheme.bodyMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingS),
                  Text(
                    feedback,
                    style: AppTheme.bodyMedium.copyWith(
                      color: color.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingM),
                  Text(
                    'Suggestions:',
                    style: AppTheme.bodyMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingS),
                  Text(
                    suggestions,
                    style: AppTheme.bodyMedium.copyWith(
                      color: color.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingM),
                  CupertinoButton(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingL,
                      vertical: AppTheme.spacingM,
                    ),
                    color: AppTheme.primaryLavender.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLoading)
                          CupertinoActivityIndicator(
                            color: AppTheme.primaryLavender,
                          )
                        else
                          Icon(
                            CupertinoIcons.book_fill,
                            color: AppTheme.primaryLavender,
                            size: 20,
                          ),
                        SizedBox(width: AppTheme.spacingS),
                        Text(
                          isLoading ? 'Finding Examples...' : 'Show Examples',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.primaryLavender,
                          ),
                        ),
                      ],
                    ),
                    onPressed: isLoading ? null : () => _showExamples(text),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 9) return AppTheme.primaryNeon;
    if (score >= 7) return AppTheme.primaryTeal;
    if (score >= 5) return AppTheme.primaryLavender;
    return AppTheme.primaryPink;
  }

  String _getNextLevelRequirement() {
    try {
      final level = int.parse(_achievementLevel.split(':')[0].replaceAll('Level ', '').trim());
      switch (level) {
        case 0:
          return 'Perfect 5 sentences to reach Level 1: Paragraph Analysis';
        case 1:
          return 'Perfect 3 paragraphs to reach Level 2: Page Analysis';
        case 2:
          return 'You\'ve reached the highest level!';
        default:
          return 'Keep writing to improve!';
      }
    } catch (e) {
      return 'Perfect 5 sentences to reach Level 1';
    }
  }

  Widget _buildGridBackground() {
    if (_gridAnimationController == null) return const SizedBox.shrink();
    
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _gridAnimationController!,
        builder: (context, child) {
          return CustomPaint(
            painter: CyberpunkGridPainter(
              animation: _gridAnimationController!.value,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CupertinoPageScaffold(
        backgroundColor: AppTheme.backgroundDark,
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Loading...'),
          backgroundColor: AppTheme.surfaceDark.withOpacity(0.9),
          border: null,
        ),
        child: Stack(
          children: [
            _buildGridBackground(),
            const Center(
              child: CupertinoActivityIndicator(
                radius: 16,
                color: AppTheme.primaryNeon,
              ),
            ),
          ],
        ),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundDark,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          widget.project.title,
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.primaryNeon,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.surfaceDark.withOpacity(0.9),
        border: null,
      ),
      child: Stack(
        children: [
          _buildGridBackground(),
          
          SafeArea(
            child: ListView(
              padding: EdgeInsets.all(AppTheme.spacingM),
              children: [
                // Achievement Level Card with improved design
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingL),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    border: Border.all(
                      color: AppTheme.primaryNeon.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: AppTheme.neonShadow(AppTheme.primaryNeon),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(AppTheme.spacingM),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryNeon.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              border: Border.all(
                                color: AppTheme.primaryNeon.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              CupertinoIcons.pencil_circle_fill,
                              color: _achievementLevel.startsWith('Level 0')
                                  ? AppTheme.primaryTeal
                                  : AppTheme.primaryNeon,
                              size: 28,
                            ),
                          ),
                          SizedBox(width: AppTheme.spacingM),
                          Text(
                            _achievementLevel,
                            style: AppTheme.headingMedium.copyWith(
                              color: _achievementLevel.startsWith('Level 0')
                                  ? AppTheme.primaryTeal
                                  : AppTheme.primaryNeon,
                              shadows: AppTheme.neonShadow(_achievementLevel.startsWith('Level 0')
                                  ? AppTheme.primaryTeal
                                  : AppTheme.primaryNeon),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppTheme.spacingM),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingL,
                          vertical: AppTheme.spacingM,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryNeon.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusL),
                          border: Border.all(
                            color: AppTheme.primaryNeon.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _getNextLevelRequirement(),
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.primaryNeon,
                            shadows: AppTheme.neonShadow(AppTheme.primaryNeon),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: AppTheme.spacingL),
                
                // Writing Area with improved design
                Container(
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
                      Padding(
                        padding: EdgeInsets.all(AppTheme.spacingL),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(AppTheme.spacingS),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryTeal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                border: Border.all(
                                  color: AppTheme.primaryTeal.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                CupertinoIcons.text_justify,
                                color: AppTheme.primaryTeal,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: AppTheme.spacingM),
                            Text(
                              'Your Story',
                              style: AppTheme.bodyLarge.copyWith(
                                color: AppTheme.primaryTeal,
                                fontWeight: FontWeight.bold,
                                shadows: AppTheme.neonShadow(AppTheme.primaryTeal),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundDark.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        child: CupertinoTextField(
                          controller: _textController,
                          placeholder: 'Start writing your story...',
                          minLines: 12,
                          maxLines: null,
                          padding: EdgeInsets.all(AppTheme.spacingL),
                          decoration: null,
                          style: AppTheme.bodyLarge.copyWith(
                            color: CupertinoColors.white,
                            height: 1.6,
                          ),
                          placeholderStyle: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.primaryTeal.withOpacity(0.4),
                            height: 1.6,
                          ),
                          cursorColor: AppTheme.primaryTeal,
                          cursorWidth: 2,
                          cursorHeight: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: AppTheme.spacingL),
                
                // Analyze Button with improved design
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    boxShadow: AppTheme.neonShadow(AppTheme.primaryNeon),
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.symmetric(vertical: AppTheme.spacingL),
                    color: AppTheme.primaryNeon.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isAnalyzing) ...[
                          const CupertinoActivityIndicator(color: CupertinoColors.white),
                          SizedBox(width: AppTheme.spacingM),
                        ],
                        Text(
                          _isAnalyzing ? 'Analyzing...' : 'Analyze Writing',
                          style: AppTheme.headingMedium.copyWith(
                            color: AppTheme.primaryNeon,
                            shadows: AppTheme.neonShadow(AppTheme.primaryNeon),
                          ),
                        ),
                        if (!_isAnalyzing) ...[
                          SizedBox(width: AppTheme.spacingM),
                          Icon(
                            CupertinoIcons.arrow_right_circle_fill,
                            color: AppTheme.primaryNeon,
                            size: 28,
                          ),
                        ],
                      ],
                    ),
                    onPressed: _isAnalyzing ? null : _analyzeAndShowResults,
                  ),
                ),

                if (_analysisData.isNotEmpty) ...[
                  SizedBox(height: AppTheme.spacingXL),
                  
                  // Analysis Results with improved design
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacingL),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      border: Border.all(
                        color: AppTheme.primaryLavender.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: AppTheme.neonShadow(AppTheme.primaryLavender),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(AppTheme.spacingM),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLavender.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                border: Border.all(
                                  color: AppTheme.primaryLavender.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                CupertinoIcons.chart_bar_fill,
                                color: AppTheme.primaryLavender,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: AppTheme.spacingM),
                            Text(
                              'Analysis Results',
                              style: AppTheme.headingMedium.copyWith(
                                color: AppTheme.primaryLavender,
                                shadows: AppTheme.neonShadow(AppTheme.primaryLavender),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingL),
                        Text(
                          _progressText,
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.primaryNeon,
                            shadows: AppTheme.neonShadow(AppTheme.primaryNeon),
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingM),
                        Container(
                          padding: EdgeInsets.all(AppTheme.spacingL),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusL),
                            border: Border.all(
                              color: AppTheme.primaryTeal.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(AppTheme.spacingS),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryTeal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                  border: Border.all(
                                    color: AppTheme.primaryTeal.withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  CupertinoIcons.lightbulb_fill,
                                  color: AppTheme.primaryTeal,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: AppTheme.spacingM),
                              Expanded(
                                child: Text(
                                  'Next Steps: $_nextSteps',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.primaryTeal,
                                    shadows: AppTheme.neonShadow(AppTheme.primaryTeal),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingM),
                  ..._analysisData.map((item) => _buildAnalysisItem(
                    item['sentence']?.toString() ?? item['paragraph']?.toString() ?? item['page']?.toString() ?? '',
                    (item['score'] as num?)?.toInt() ?? 0,
                    item['isPerfect'] as bool? ?? false,
                    item['feedback']?.toString() ?? '',
                    item['suggestions']?.toString() ?? '',
                  )).toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Add CyberpunkGridPainter class
class CyberpunkGridPainter extends CustomPainter {
  final double animation;

  CyberpunkGridPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 30.0;
    final verticalLines = (size.width / spacing).ceil();
    final horizontalLines = (size.height / spacing).ceil();

    // Draw vertical lines
    for (var i = 0; i < verticalLines; i++) {
      final x = i * spacing;
      final startY = size.height * animation;
      paint.color = AppTheme.primaryNeon.withOpacity(0.1 * (1 - i / verticalLines));
      canvas.drawLine(
        Offset(x, startY),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (var i = 0; i < horizontalLines; i++) {
      final y = i * spacing;
      final startX = size.width * (1 - animation);
      paint.color = AppTheme.primaryTeal.withOpacity(0.1 * (1 - i / horizontalLines));
      canvas.drawLine(
        Offset(startX, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CyberpunkGridPainter oldDelegate) => true;
} 