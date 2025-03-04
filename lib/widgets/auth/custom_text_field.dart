import 'package:flutter/cupertino.dart';
import '../../theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? placeholder;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final bool enabled;
  final FocusNode? focusNode;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.placeholder,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.validator,
    this.enabled = true,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText.isNotEmpty) ...[
          Text(
            labelText,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
        ],
        Container(
          decoration: BoxDecoration(
            color: enabled ? AppTheme.surfaceDark : AppTheme.backgroundDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: AppTheme.textSecondary.withOpacity(0.2),
            ),
            boxShadow: AppTheme.neonShadow(AppTheme.primaryNeon),
          ),
          child: CupertinoTextField(
            controller: controller,
            placeholder: placeholder ?? labelText,
            placeholderStyle: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.surfaceLight,
            ),
            obscureText: obscureText,
            keyboardType: keyboardType,
            suffix: suffixIcon,
            enabled: enabled,
            focusNode: focusNode,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingM,
            ),
            decoration: BoxDecoration(
              color: CupertinoColors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
        ),
        if (validator != null) ...[
          const SizedBox(height: AppTheme.spacingXS),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              final error = validator!(value.text);
              return error != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: AppTheme.spacingXS),
                      child: Text(
                        error,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryPink,
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ],
    );
  }
} 