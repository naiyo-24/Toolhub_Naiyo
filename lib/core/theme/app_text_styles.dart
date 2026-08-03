import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // App Logo - Space Grotesk ExtraBold (800)
  static const TextStyle logoText = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontWeight: FontWeight.w800,
    fontSize: 36,
    color: AppColors.primaryBlack,
  );

  // Hero Title - Archivo Black (400)
  static const TextStyle heroTitle = TextStyle(
    fontFamily: 'ArchivoBlack',
    fontWeight: FontWeight.w400,
    fontSize: 40,
    color: AppColors.primaryBlack,
  );

  // Screen Heading - Space Grotesk Bold (700)
  static const TextStyle screenHeading = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontWeight: FontWeight.w700,
    fontSize: 30,
    color: AppColors.primaryBlack,
  );

  // Section Title - Space Grotesk Bold (700)
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontWeight: FontWeight.w700,
    fontSize: 22,
    color: AppColors.primaryBlack,
  );

  // Tool Card Title - Space Grotesk SemiBold (600)
  static const TextStyle toolCardTitle = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: AppColors.primaryBlack,
  );

  // Body Text - General Sans Regular (400)
  static const TextStyle bodyText = TextStyle(
    fontFamily: 'GeneralSans',
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColors.primaryBlack,
  );

  // Caption - General Sans Medium (500)
  static const TextStyle caption = TextStyle(
    fontFamily: 'GeneralSans',
    fontWeight: FontWeight.w500,
    fontSize: 12,
    color: AppColors.primaryBlack,
  );

  // Buttons - Space Grotesk Bold (700)
  static const TextStyle buttonText = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontWeight: FontWeight.w700,
    fontSize: 16,
    color: AppColors.primaryWhite,
  );

  // Bottom Navigation - Space Grotesk SemiBold (600)
  static const TextStyle bottomNavigation = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontWeight: FontWeight.w600,
    fontSize: 12,
    color: AppColors.primaryBlack,
  );
}
