import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../navigation/bottom_nav_config.dart';

class BottomNavBar extends StatelessWidget {
  final Function(int) onSwitchTab;
  final int currentIndex;

  const BottomNavBar({
    Key? key,
    required this.onSwitchTab,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXXL),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNeon.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(BottomNavConfig.items.length, (index) {
          final item = BottomNavConfig.items[index];
          final isSelected = currentIndex == index;
          
          return GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onSwitchTab(index);
            },
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.primaryNeon.withOpacity(0.2)
                    : AppTheme.primaryNeon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                boxShadow: isSelected ? AppTheme.neonShadow(AppTheme.primaryNeon) : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    color: isSelected ? AppTheme.primaryNeon : AppTheme.surfaceLight.withOpacity(0.7),
                    size: 24,
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    item.label,
                    style: AppTheme.bodySmall.copyWith(
                      color: isSelected ? AppTheme.primaryNeon : AppTheme.surfaceLight.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
} 