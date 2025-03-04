import 'package:flutter/cupertino.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../theme/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isSmall;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isSmall = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: AppTheme.durationFast,
      opacity: isLoading ? 0.8 : 1.0,
      child: Container(
        width: double.infinity,
        height: isSmall ? 40 : 50,
        decoration: BoxDecoration(
          gradient: isOutlined
              ? null
              : LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: isOutlined
              ? Border.all(color: AppTheme.primaryBlue, width: 2)
              : null,
          boxShadow: isOutlined ? null : AppTheme.shadowSmall,
        ),
        child: CupertinoButton(
          onPressed: isLoading ? () {} : onPressed,
          padding: EdgeInsets.zero,
          child: AnimatedContainer(
            duration: AppTheme.durationFast,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Center(
              child: _buildChild(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChild() {
    return isLoading
        ? LoadingAnimationWidget.staggeredDotsWave(
            color: isOutlined ? AppTheme.primaryBlue : AppTheme.surfaceLight,
            size: isSmall ? 20 : 25,
          )
        : Text(
            text,
            style: AppTheme.buttonText.copyWith(
              color: isOutlined ? AppTheme.primaryBlue : AppTheme.surfaceLight,
              fontSize: isSmall ? 14 : 16,
            ),
          );
  }
} 