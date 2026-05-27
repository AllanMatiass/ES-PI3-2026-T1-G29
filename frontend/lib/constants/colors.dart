// Autor: Allan Giovanni Matias Paes - 25008211
import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF00A84E);
  static const Color primaryDark = Color(0xFF00873E);
  static final Color primaryLight = const Color(0xFF00A84E).withOpacity(0.1);

  // Neutral colors
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;
  
  static final Color grey50 = Colors.grey[50]!;
  static final Color grey100 = Colors.grey[100]!;
  static final Color grey200 = Colors.grey[200]!;
  static final Color grey300 = Colors.grey[300]!;
  static final Color grey400 = Colors.grey[400]!;
  static final Color grey600 = Colors.grey[600]!;
  static final Color grey700 = Colors.grey[700]!;
  static final Color grey800 = Colors.grey[800]!;
  static final Color grey900 = Colors.grey[900]!;

  // Feedback colors
  static const Color success = Color(0xFF25A830);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B); // Orange-ish Amber
  static final Color warningLight = const Color(0xFFF59E0B).withOpacity(0.1);
  static const Color info = Color(0xFF3B82F6); // Standard Blue
  static final Color infoLight = const Color(0xFF3B82F6).withOpacity(0.1);

  // Chart Colors (for AssetsPieChart)
  static const List<Color> chartPalette = [
    primary,
    info,
    warning,
    Color(0xFF8E24AA), // Purple
    Color(0xFFF4511E), // Deep Orange
    Color(0xFF00ACC1), // Cyan
    Color(0xFFD81B60), // Pink
    Color(0xFF43A047), // Green
  ];

  // Shimmer colors
  static Color shimmerBaseLight = Colors.grey[300]!;
  static Color shimmerHighlightLight = Colors.grey[100]!;
  static Color shimmerBaseDark = Colors.grey[800]!;
  static Color shimmerHighlightDark = Colors.grey[700]!;
}
