import 'package:flutter/material.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';

class DialogUtils {
  static void showAIBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            border: Border(top: BorderSide(color: Colors.black, width: 3), left: BorderSide(color: Colors.black, width: 3), right: BorderSide(color: Colors.black, width: 3)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryPink,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(6, 6), blurRadius: 0),
                  ],
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.black, size: 56),
              ),
              const SizedBox(height: 32),
              Text(
                'AI TOOLS',
                style: AppTextStyles.heroTitle.copyWith(fontSize: 32, letterSpacing: 2),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
                  ],
                ),
                child: const Text('PREMIUM FEATURE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.5)),
              ),
              const SizedBox(height: 24),
              const Text(
                'We are building something magical! Our advanced Artificial Intelligence toolkit is currently in development and will be available exclusively for Premium users very soon.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black, height: 1.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.black, width: 3),
                    ),
                  ).copyWith(
                    shadowColor: WidgetStateProperty.all(Colors.transparent),
                  ),
                  child: const Text('GOT IT!', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  static void showComingSoonBottomSheet(BuildContext context, {String title = 'COMING SOON'}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            border: Border(top: BorderSide(color: Colors.black, width: 3), left: BorderSide(color: Colors.black, width: 3), right: BorderSide(color: Colors.black, width: 3)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(6, 6), blurRadius: 0),
                  ],
                ),
                child: const Icon(Icons.construction_rounded, color: Colors.black, size: 56),
              ),
              const SizedBox(height: 32),
              Text(
                title.toUpperCase(),
                style: AppTextStyles.heroTitle.copyWith(fontSize: 28, letterSpacing: 1),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'We are building something magical! This tool is currently in development and will be available in a future update.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black, height: 1.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.black, width: 3),
                    ),
                  ).copyWith(
                    shadowColor: WidgetStateProperty.all(Colors.transparent),
                  ),
                  child: const Text('GOT IT!', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
