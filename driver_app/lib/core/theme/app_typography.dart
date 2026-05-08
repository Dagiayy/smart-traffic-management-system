import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography scale — Inter font, restrained sizes, hierarchy via weight + size only.
class AppTypography {
  AppTypography._();

  static TextStyle _base(double size, FontWeight weight, {Color? color}) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.textPrimary,
      height: 1.4,
      letterSpacing: -0.1,
    );
  }

  // Display
  static TextStyle get displayLarge => _base(32, FontWeight.w700);
  static TextStyle get displayMedium => _base(28, FontWeight.w700);

  // Headings
  static TextStyle get h1 => _base(24, FontWeight.w700);
  static TextStyle get h2 => _base(20, FontWeight.w600);
  static TextStyle get h3 => _base(18, FontWeight.w600);
  static TextStyle get h4 => _base(16, FontWeight.w600);

  // Body
  static TextStyle get bodyLarge => _base(16, FontWeight.w400);
  static TextStyle get bodyMedium => _base(14, FontWeight.w400);
  static TextStyle get bodySmall =>
      _base(13, FontWeight.w400, color: AppColors.textSecondary);

  // Labels
  static TextStyle get labelLarge => _base(15, FontWeight.w600);
  static TextStyle get labelMedium => _base(13, FontWeight.w500);
  static TextStyle get labelSmall =>
      _base(12, FontWeight.w500, color: AppColors.textSecondary);

  // Captions / metadata
  static TextStyle get caption =>
      _base(11, FontWeight.w500, color: AppColors.textTertiary);

  // Buttons
  static TextStyle get button => _base(15, FontWeight.w600);

  // Numeric (for amounts, scores) — slightly tighter
  static TextStyle numeric(double size, FontWeight weight, {Color? color}) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.textPrimary,
      height: 1.2,
      letterSpacing: -0.5,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
