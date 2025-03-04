import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../components/bottom_nav_bar.dart';
import '../services/user_service.dart';
import '../services/book_service.dart';
import 'dart:ui' as ui;
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  final Function(int)? onSwitchTab;
  final int? currentIndex;

  const ProfileScreen({
    Key? key,
    this.onSwitchTab,
    this.currentIndex,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _gridAnimationController;
  final TextEditingController _bookController = TextEditingController();
  bool _isAddingBook = false;
  bool _isLoadingRecommendations = false;
  List<String> _recommendations = [];

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
    _bookController.dispose();
    super.dispose();
  }

  Future<void> _addFavoriteBook(BuildContext context, UserService userService) async {
    if (_bookController.text.isEmpty) return;

    setState(() => _isAddingBook = true);

    try {
      // Search for matching books
      final bookService = Provider.of<BookService>(context, listen: false);
      final searchResults = await bookService.searchBooks(_bookController.text);
      
      if (searchResults.isEmpty) {
        throw Exception('No matching books found');
      }

      // Show book selection dialog
      final selectedBook = await showCupertinoModalPopup<Book>(
        context: context,
        builder: (context) => _BookSelectionSheet(books: searchResults),
      );

      if (selectedBook != null) {
        final selectedBookJson = jsonEncode({
          'title': selectedBook.title,
          'author': selectedBook.author,
          'description': selectedBook.description,
          'genre': selectedBook.genre,
          'yearPublished': selectedBook.yearPublished?.toString(),
        });
        
        // Add the selected book
        await userService.addFavoriteBook(selectedBookJson);
        _bookController.clear();
        
        // Get recommendations based on the selected book
        setState(() => _isLoadingRecommendations = true);
        final recommendations = await bookService.getRecommendations(selectedBook);
        setState(() {
          _recommendations = recommendations.map((book) => jsonEncode({
            'title': book.title,
            'author': book.author,
            'description': book.description,
            'genre': book.genre,
            'yearPublished': book.yearPublished?.toString(),
          })).toList();
          _isLoadingRecommendations = false;
        });
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
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingBook = false;
          _isLoadingRecommendations = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService?>(context);

    if (userService == null) {
      return CupertinoPageScaffold(
        backgroundColor: AppTheme.backgroundDark,
        child: Center(
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
                'Please sign in to view your profile',
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
        ),
      );
    }

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
                    'Profile',
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
                child: CustomScrollView(
                  slivers: [
                    CupertinoSliverRefreshControl(
                      onRefresh: () async {
                        // Refresh user data
                        await userService.refreshUserData();
                      },
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Header
                            _buildProfileHeader(userService),
                            const SizedBox(height: AppTheme.spacingXL),

                            // Stats Section
                            _buildStatsSection(userService),
                            const SizedBox(height: AppTheme.spacingXL),

                            // Writing Goals
                            _buildWritingGoals(userService),
                            const SizedBox(height: AppTheme.spacingXL),

                            // Favorite Books Section
                            _buildFavoriteBooksSection(userService),
                            const SizedBox(height: AppTheme.spacingL),

                            // Book Recommendations
                            if (_recommendations.isNotEmpty)
                              _buildRecommendations(),
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

  Widget _buildProfileHeader(UserService userService) {
    return StreamBuilder<UserProfile>(
      stream: userService.userProfileStream,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark.withOpacity(0.8),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: AppTheme.primaryNeon.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: AppTheme.neonShadow(AppTheme.primaryNeon),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _showEditProfileSheet(context, userService, profile),
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryNeon.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                        border: Border.all(
                          color: AppTheme.primaryNeon.withOpacity(0.5),
                          width: 2,
                        ),
                        image: profile?.photoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(profile!.photoUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: profile?.photoUrl == null
                          ? Icon(
                              CupertinoIcons.person_fill,
                              color: AppTheme.primaryNeon,
                              size: 40,
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryNeon,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppTheme.neonShadow(AppTheme.primaryNeon),
                        ),
                        child: Icon(
                          CupertinoIcons.camera_fill,
                          color: AppTheme.surfaceDark,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingL),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showEditProfileSheet(context, userService, profile),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              profile?.displayName ?? 'Writer',
                              style: AppTheme.headingMedium.copyWith(
                                color: AppTheme.surfaceLight,
                                shadows: [
                                  Shadow(
                                    color: AppTheme.primaryNeon.withOpacity(0.5),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Icon(
                            CupertinoIcons.pencil_circle_fill,
                            color: AppTheme.primaryNeon,
                            size: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        profile?.bio ?? 'No bio yet',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.surfaceLight.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileSheet(BuildContext context, UserService userService, UserProfile? profile) {
    final nameController = TextEditingController(text: profile?.displayName ?? '');
    final bioController = TextEditingController(text: profile?.bio ?? '');
    String? photoUrl = profile?.photoUrl;
    bool isUploading = false;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXL),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Edit Profile',
                  style: AppTheme.headingMedium.copyWith(
                    color: AppTheme.surfaceLight,
                    shadows: [
                      Shadow(
                        color: AppTheme.primaryNeon.withOpacity(0.5),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                GestureDetector(
                  onTap: () async {
                    // TODO: Implement image picker and upload
                    // For now, we'll just show a dialog
                    showCupertinoDialog(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: const Text('Coming Soon'),
                        content: const Text('Photo upload will be available in the next update.'),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('OK'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryNeon.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(60),
                            border: Border.all(
                              color: AppTheme.primaryNeon.withOpacity(0.5),
                              width: 2,
                            ),
                            image: photoUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(photoUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: photoUrl == null
                              ? Icon(
                                  CupertinoIcons.person_fill,
                                  color: AppTheme.primaryNeon,
                                  size: 60,
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryNeon,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: AppTheme.neonShadow(AppTheme.primaryNeon),
                            ),
                            child: Icon(
                              CupertinoIcons.camera_fill,
                              color: AppTheme.surfaceDark,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: AppTheme.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryNeon.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(
                      color: AppTheme.primaryNeon.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: CupertinoTextField(
                    controller: nameController,
                    placeholder: 'Display Name',
                    placeholderStyle: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.surfaceLight.withOpacity(0.3),
                    ),
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.surfaceLight,
                    ),
                    decoration: null,
                    cursorColor: AppTheme.primaryNeon,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: AppTheme.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryNeon.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(
                      color: AppTheme.primaryNeon.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: CupertinoTextField(
                    controller: bioController,
                    placeholder: 'Bio',
                    placeholderStyle: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.surfaceLight.withOpacity(0.3),
                    ),
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.surfaceLight,
                    ),
                    decoration: null,
                    cursorColor: AppTheme.primaryNeon,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            border: Border.all(
                              color: AppTheme.primaryTeal.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.primaryTeal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: GestureDetector(
                        onTap: isUploading
                            ? null
                            : () async {
                                setState(() => isUploading = true);
                                try {
                                  await userService.updateProfile(
                                    displayName: nameController.text,
                                    bio: bioController.text,
                                    photoUrl: photoUrl,
                                  );
                                  Navigator.pop(context);
                                } catch (e) {
                                  showCupertinoDialog(
                                    context: context,
                                    builder: (context) => CupertinoAlertDialog(
                                      title: const Text('Error'),
                                      content: Text(e.toString()),
                                      actions: [
                                        CupertinoDialogAction(
                                          child: const Text('OK'),
                                          onPressed: () => Navigator.pop(context),
                                        ),
                                      ],
                                    ),
                                  );
                                } finally {
                                  setState(() => isUploading = false);
                                }
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryNeon.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            border: Border.all(
                              color: AppTheme.primaryNeon.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: isUploading
                              ? const CupertinoActivityIndicator()
                              : Text(
                                  'Save',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.primaryNeon,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(UserService userService) {
    return StreamBuilder<UserStats>(
      stream: userService.userStatsStream,
      builder: (context, snapshot) {
        final stats = snapshot.data;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Writing Stats',
              style: AppTheme.headingMedium.copyWith(
                color: AppTheme.surfaceLight,
                shadows: [
                  Shadow(
                    color: AppTheme.primaryTeal.withOpacity(0.5),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Words Written',
                    '${stats?.totalWords ?? 0}',
                    AppTheme.primaryTeal,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: _buildStatCard(
                    'Projects',
                    '${stats?.projectCount ?? 0}',
                    AppTheme.primaryNeon,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: _buildStatCard(
                    'Daily Streak',
                    '${stats?.currentStreak ?? 0}',
                    AppTheme.primaryLavender,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
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
        children: [
          Text(
            value,
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
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.surfaceLight.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWritingGoals(UserService userService) {
    return StreamBuilder<UserGoals>(
      stream: userService.userGoalsStream,
      builder: (context, snapshot) {
        final goals = snapshot.data;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Writing Goals',
              style: AppTheme.headingMedium.copyWith(
                color: AppTheme.surfaceLight,
                shadows: [
                  Shadow(
                    color: AppTheme.primaryLavender.withOpacity(0.5),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
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
                children: [
                  _buildGoalProgress(
                    'Daily Word Goal',
                    goals?.dailyWordCount ?? 0,
                    goals?.dailyWordGoal ?? 1000,
                    AppTheme.primaryTeal,
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildGoalProgress(
                    'Weekly Projects',
                    goals?.weeklyProjectCount ?? 0,
                    goals?.weeklyProjectGoal ?? 3,
                    AppTheme.primaryNeon,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGoalProgress(String label, int current, int target, Color color) {
    final progress = (current / target).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.surfaceLight.withOpacity(0.7),
              ),
            ),
            Text(
              '$current / $target',
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
            widthFactor: progress,
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
    );
  }

  Widget _buildFavoriteBooksSection(UserService userService) {
    return StreamBuilder<List<String>>(
      stream: userService.favoriteBooksStream,
      builder: (context, snapshot) {
        final books = snapshot.data ?? [];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Favorite Books',
              style: AppTheme.headingMedium.copyWith(
                color: AppTheme.surfaceLight,
                shadows: [
                  Shadow(
                    color: AppTheme.primaryNeon.withOpacity(0.5),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
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
                  // Book list
                  ...books.map((bookData) => _buildBookItem(bookData, userService)),
                  const SizedBox(height: AppTheme.spacingM),

                  // Add book input
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingM,
                      vertical: AppTheme.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNeon.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(
                        color: AppTheme.primaryNeon.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoTextField(
                            controller: _bookController,
                            placeholder: 'Add a favorite book',
                            placeholderStyle: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.surfaceLight.withOpacity(0.3),
                            ),
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.surfaceLight,
                            ),
                            decoration: null,
                            cursorColor: AppTheme.primaryNeon,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        GestureDetector(
                          onTap: _isAddingBook
                              ? null
                              : () => _addFavoriteBook(context, userService),
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.spacingS),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryNeon.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              border: Border.all(
                                color: AppTheme.primaryNeon.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: _isAddingBook
                                ? const CupertinoActivityIndicator()
                                : Icon(
                                    CupertinoIcons.add,
                                    color: AppTheme.primaryNeon,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBookItem(String bookData, UserService userService) {
    Book book;
    try {
      // Try to parse as JSON first
      book = Book.fromJson(jsonDecode(bookData));
    } catch (e) {
      // If JSON parsing fails, try to parse the plain text format
      final parts = bookData.split(" by ");
      if (parts.length == 2) {
        book = Book(
          title: parts[0].replaceAll('"', ''),
          author: parts[1],
          description: '',
          genre: 'Unknown',
        );
      } else {
        // Fallback for completely unknown format
        book = Book(
          title: bookData,
          author: 'Unknown Author',
          description: '',
          genre: 'Unknown',
        );
      }
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withOpacity(0.8),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: AppTheme.primaryNeon.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingS),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNeon.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(
                        color: AppTheme.primaryNeon.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      CupertinoIcons.book_fill,
                      color: AppTheme.primaryNeon,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.surfaceLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXS),
                        Text(
                          'by ${book.author}',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.surfaceLight.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXS),
                        Text(
                          book.genre,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.primaryNeon,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => userService.removeFavoriteBook(bookData),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(
                          color: AppTheme.primaryTeal.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.xmark,
                        color: AppTheme.primaryTeal,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (book.description.isNotEmpty) ...[
              Container(
                height: 1,
                color: AppTheme.primaryNeon.withOpacity(0.1),
              ),
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Text(
                  book.description,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.surfaceLight.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Books',
          style: AppTheme.headingMedium.copyWith(
            color: AppTheme.surfaceLight,
            shadows: [
              Shadow(
                color: AppTheme.primaryTeal.withOpacity(0.5),
                blurRadius: 5,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark.withOpacity(0.8),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: AppTheme.primaryTeal.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: AppTheme.neonShadow(AppTheme.primaryTeal),
          ),
          child: _isLoadingRecommendations
              ? const Center(child: CupertinoActivityIndicator())
              : Column(
                  children: _recommendations.map((bookData) => _buildBookItem(
                    bookData,
                    Provider.of<UserService>(context),
                  )).toList(),
                ),
        ),
      ],
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

class _BookSelectionSheet extends StatelessWidget {
  final List<Book> books;

  const _BookSelectionSheet({required this.books});

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: const Text('Select Book'),
      message: const Text('Choose the book you meant:'),
      actions: books.map((book) => CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(context, book),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book.title,
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.primaryNeon,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              'by ${book.author}',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.surfaceLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              book.description,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.surfaceLight.withOpacity(0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      )).toList(),
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(context),
        isDestructiveAction: true,
        child: const Text('Cancel'),
      ),
    );
  }
} 