import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primaryPurple,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryPurple,
        secondary: AppColors.primaryYellow,

        surface: AppColors.primaryWhite,
        onSurface: AppColors.primaryBlack, // Borders, text, icons in light mode
      ),
      textTheme: _buildTextTheme(AppColors.primaryBlack),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryPurple,
      scaffoldBackgroundColor: const Color(0xFF111111),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryPurple,
        secondary: AppColors.primaryYellow,

        surface: Color(0xFF1A1A1A), // Cards background in dark mode
        onSurface: AppColors.primaryWhite, // Borders, text, icons in dark mode
      ),
      textTheme: _buildTextTheme(AppColors.primaryWhite),
      useMaterial3: true,
    );
  }

  static TextTheme _buildTextTheme(Color color) {
    return TextTheme(
      displayLarge: AppTextStyles.heroTitle.copyWith(color: color),
      displayMedium: AppTextStyles.screenHeading.copyWith(color: color),
      titleLarge: AppTextStyles.sectionTitle.copyWith(color: color),
      titleMedium: AppTextStyles.toolCardTitle.copyWith(color: color),
      bodyLarge: AppTextStyles.bodyText.copyWith(color: color),
      bodyMedium: AppTextStyles.caption.copyWith(color: color),
      labelLarge: AppTextStyles.buttonText.copyWith(color: color),
    );
  }
}
