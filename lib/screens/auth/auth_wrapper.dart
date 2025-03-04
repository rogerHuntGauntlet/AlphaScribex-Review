import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const CupertinoActivityIndicator();
        }
        
        return authProvider.isAuthenticated
            ? const HomeScreen()
            : const LoginScreen();
      },
    );
  }
} 