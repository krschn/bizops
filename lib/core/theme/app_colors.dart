import 'package:flutter/material.dart';

abstract class AppColors {
  // Backgrounds
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F8FA);
  static const Color surfaceVariant = Color(0xFFF0F0F5);

  // Navy Blue — primary accent (used sparingly)
  static const Color primary = Color(0xFF1B2A4A);
  static const Color primaryLight = Color(0xFF2E4270);
  static const Color primaryMuted = Color(0xFFE8EBF2);

  // Text
  static const Color textPrimary = Color(0xFF0D0D0D);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFFB0B7C3);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFD1D5DB);

  // Semantic
  static const Color error = Color(0xFFC0392B);
  static const Color errorSurface = Color(0xFFFDEDED);
  static const Color success = Color(0xFF1A7A4A);
  static const Color warning = Color(0xFFB45309);

  // Trash / Soft-delete
  static const Color trashAccent = Color(0xFF9CA3AF);
}
