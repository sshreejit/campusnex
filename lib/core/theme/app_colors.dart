import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- BRAND (Charcoal Steel Theme) ---
  static const Color charcoalSteel = Color(0xFF36454F); // Your core color
  static const Color primary = charcoalSteel;
  static const Color primaryDark = Color(0xFF263238);   // Deeper slate
  static const Color primaryLight = Color(0xFF546E7A);  // Lighter steel gray
  static const Color accent = Color(0xFF00BFA5);        // Keep for a "pop" of color

  // --- NEUTRALS (Light/Surface) ---
  static const Color background = Color(0xFFF1F3F4);    // Soft gray background
  static const Color surface = Color(0xFFFFFFFF);       // White cards
  static const Color surfaceVariant = Color(0xFFDEE4E7); // Steel-tinted light gray

  // --- TEXT (High Contrast) ---
  // We use very dark slate for primary text to match the charcoal theme
  static const Color textPrimary = Color(0xFF1C252C);
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color textHint = Color(0xFF90A4AE);
  static const Color textOnPrimary = Colors.white;      // Crucial for Charcoal buttons

  // --- STATUS ---
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // --- ROLE BADGES (Refined for Charcoal) ---
  static const Color superUserColor = Color(0xFF6366F1); // Indigo
  static const Color adminColor = charcoalSteel;        // Admin = Brand
  static const Color coordinatorColor = Color(0xFF0D9488); // Teal
  static const Color staffColor = Color(0xFF16A34A);    // Green
  static const Color parentColor = Color(0xFFD97706);   // Amber

  // --- BORDER & DIVIDER ---
  static const Color border = Color(0xFFCFD8DC);
  static const Color divider = Color(0xFFECEFF1);
}