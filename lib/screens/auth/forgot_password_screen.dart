import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/custom_button.dart';
import '../../widgets/auth/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showError('Please enter your email address');
      return;
    }

    setState(() => _isSubmitting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resetPassword(_emailController.text.trim());

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (success) {
        _showSuccess('Password reset email sent. Please check your inbox.');
        Navigator.of(context).pop();
      } else if (authProvider.error != null) {
        _showError(authProvider.error!);
      }
    }
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

  void _showSuccess(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
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
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.surfaceLight,
        border: null,
        middle: Text(
          'Reset Password',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  CupertinoIcons.lock_circle,
                  size: 64,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(height: AppTheme.spacingL),
                Text(
                  'Forgot Your Password?',
                  style: AppTheme.headingMedium.copyWith(
                    color: AppTheme.primaryBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  'Enter your email address and we\'ll send you instructions to reset your password.',
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingXL),
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isSubmitting,
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
                const SizedBox(height: AppTheme.spacingL),
                CustomButton(
                  text: 'Send Reset Link',
                  onPressed: _isSubmitting ? () {} : () async {
                    await _resetPassword();
                  },
                  isLoading: _isSubmitting,
                ),
                const SizedBox(height: AppTheme.spacingM),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Back to Sign In',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 