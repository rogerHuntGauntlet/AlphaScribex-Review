import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'screens/main_screen.dart';
import 'screens/auth/login_screen.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'services/achievement_service.dart';
import 'services/project_service.dart';
import 'theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/user_service.dart';
import 'services/book_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env.local");
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        Provider<AchievementService>(create: (_) => AchievementService()),
        Provider<ProjectService>(create: (_) => ProjectService()),
        Provider<BookService>(
          create: (_) => BookService(dotenv.env['OPENAI_API_KEY'] ?? ''),
        ),
        ProxyProvider<app_auth.AuthProvider, String?>(
          update: (context, auth, previous) => auth.user?.uid,
        ),
        ProxyProvider<String?, UserService?>(
          update: (_, userId, __) => userId != null
              ? UserService(FirebaseFirestore.instance, userId)
              : null,
        ),
      ],
      child: const CupertinoApp(
        title: 'Alpha Scribex',
        theme: CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: AppTheme.primaryNeon,
        ),
        home: RootNavigator(),
      ),
    );
  }
}

class RootNavigator extends StatelessWidget {
  const RootNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<app_auth.AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const CupertinoPageScaffold(
            child: Center(
              child: CupertinoActivityIndicator(),
            ),
          );
        }

        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        return const MainScreen();
      },
    );
  }
}
