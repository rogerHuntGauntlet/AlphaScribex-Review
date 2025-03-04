import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/custom_button.dart';
import '../../widgets/auth/custom_text_field.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (!success && authProvider.error != null) {
          _showError(authProvider.error!);
        }
      }
    }
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );
  }

  void _navigateToForgotPassword() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const ForgotPasswordScreen(),
      ),
    );
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundLight,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                boxShadow: AppTheme.shadowMedium,
              ),
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome Back!',
                      style: AppTheme.headingLarge.copyWith(
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      'Sign in to continue',
                      style: AppTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingXL),
                    CustomTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    CustomTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                      suffixIcon: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _togglePasswordVisibility,
                        child: Icon(
                          _obscurePassword
                              ? CupertinoIcons.eye
                              : CupertinoIcons.eye_slash,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Align(
                      alignment: Alignment.centerRight,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _navigateToForgotPassword,
                        child: Text(
                          'Forgot Password?',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                    CustomButton(
                      text: 'Sign In',
                      onPressed: _isLoading ? () {} : () async {
                        await _handleLogin();
                      },
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: AppTheme.bodyMedium,
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _navigateToRegister,
                          child: Text(
                            'Sign Up',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }
} 