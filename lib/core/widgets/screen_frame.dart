import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ScreenFrame extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;

  const ScreenFrame({
    super.key,
    required this.child,
    this.borderColor = AppColors.charcoalSteel,
    this.borderWidth = 4.0, // This makes it "Thick"
    this.borderRadius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // The background color of the outer "gap"
      color: AppColors.charcoalSteel,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        // This ensures the child (screen content) is also rounded
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          child: child,
        ),
      ),
    );
  }
}