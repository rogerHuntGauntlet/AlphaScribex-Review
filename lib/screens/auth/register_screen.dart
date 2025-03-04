import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/custom_button.dart';
import '../../widgets/auth/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
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

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showError('Passwords do not match');
        return;
      }
      
      setState(() => _isLoading = true);
      
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.register(
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundLight,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.surfaceLight,
        border: null,
        middle: Text(
          'Create Account',
          style: AppTheme.headingMedium.copyWith(
            color: AppTheme.primaryBlue,
          ),
        ),
      ),
      child: SafeArea(
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Join Scribex',
                    style: AppTheme.headingLarge.copyWith(
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Create an account to get started',
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
                  const SizedBox(height: AppTheme.spacingM),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirm Password',
                    obscureText: _obscureConfirmPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    suffixIcon: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _toggleConfirmPasswordVisibility,
                      child: Icon(
                        _obscureConfirmPassword
                            ? CupertinoIcons.eye
                            : CupertinoIcons.eye_slash,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  CustomButton(
                    text: 'Create Account',
                    onPressed: _isLoading ? () {} : () async {
                      await _handleRegister();
                    },
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: AppTheme.bodyMedium,
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Sign In',
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
    );
  }
} 