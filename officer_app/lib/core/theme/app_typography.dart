import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle _base(double size, FontWeight weight, {Color? color}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.textPrimary,
        height: 1.4,
        letterSpacing: -0.1,
      );

  static TextStyle get displayLarge => _base(30, FontWeight.w700);
  static TextStyle get displayMedium => _base(26, FontWeight.w700);

  static TextStyle get h1 => _base(22, FontWeight.w700);
  static TextStyle get h2 => _base(18, FontWeight.w700);
  static TextStyle get h3 => _base(16, FontWeight.w600);
  static TextStyle get h4 => _base(15, FontWeight.w600);

  static TextStyle get bodyLarge  => _base(15, FontWeight.w400);
  static TextStyle get bodyMedium => _base(14, FontWeight.w400);
  static TextStyle get bodySmall  => _base(13, FontWeight.w400, color: AppColors.textSecondary);

  static TextStyle get labelLarge  => _base(14, FontWeight.w600);
  static TextStyle get labelMedium => _base(13, FontWeight.w500);
  static TextStyle get labelSmall  => _base(12, FontWeight.w500, color: AppColors.textSecondary);

  static TextStyle get caption => _base(11, FontWeight.w500, color: AppColors.textTertiary);
  static TextStyle get button  => _base(14, FontWeight.w700);

  /// Tabular figures for counts, IDs, times
  static TextStyle numeric(double size, FontWeight weight, {Color? color}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.textPrimary,
        height: 1.2,
        letterSpacing: -0.4,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
