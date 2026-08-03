import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import '../widgets/onboarding_illustrations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() async {
    if (_currentPage == 2) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
      if (mounted) {
        context.go('/');
      }
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onSkip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                ],
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentPage < 2)
            GestureDetector(
              onTap: _onSkip,
              child: Text(
                'Skip',
                style: AppTextStyles.toolCardTitle.copyWith(
                  color: AppColors.primaryBlack.withValues(alpha: 0.6),
                ),
              ),
            )
          else
            const SizedBox(height: 24), // Placeholder to maintain height
        ],
      ),
    );
  }

  Widget _buildPage1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            'WELCOME TO',
            style: AppTextStyles.heroTitle.copyWith(fontSize: 28),
            textAlign: TextAlign.center,
          ),
          Text(
            'TOOL',
            style: AppTextStyles.heroTitle.copyWith(fontSize: 52, height: 1.0),
            textAlign: TextAlign.center,
          ),
          Text(
            'HUB',
            style: AppTextStyles.heroTitle.copyWith(fontSize: 52, height: 1.0, color: AppColors.primaryPurple),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'All-in-one platform with\npowerful tools for\nsmarter everyday.',
            style: AppTextStyles.bodyText.copyWith(fontSize: 16, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          const WelcomeIllustration(),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            'ALL YOUR',
            style: AppTextStyles.heroTitle.copyWith(fontSize: 40, height: 1.1),
            textAlign: TextAlign.center,
          ),
          Text(
            'TOOLS,',
            style: AppTextStyles.heroTitle.copyWith(fontSize: 40, height: 1.1),
            textAlign: TextAlign.center,
          ),
          Text(
            'ONE PLACE.',
            style: AppTextStyles.heroTitle.copyWith(fontSize: 40, height: 1.1, color: AppColors.primaryPurple),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'Access 20+ powerful tools\ndesigned to simplify your\ndaily tasks.',
            style: AppTextStyles.bodyText.copyWith(fontSize: 16, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          const Expanded(flex: 3, child: FittedBox(fit: BoxFit.contain, child: PhoneGridIllustration())),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            'SMART.',
            style: AppTextStyles.heroTitle.copyWith(fontSize: 40, height: 1.1),
            textAlign: TextAlign.center,
          ),
          Text(
            'FAST.',
            style: AppTextStyles.heroTitle.copyWith(fontSize: 40, height: 1.1),
            textAlign: TextAlign.center,
          ),
          Text(
            'RELIABLE.',
            style: AppTextStyles.heroTitle.copyWith(fontSize: 40, height: 1.1, color: AppColors.primaryPurple),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'Built for speed and\nreliability so you can\nget more done.',
            style: AppTextStyles.bodyText.copyWith(fontSize: 16, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          const SecurityShieldIllustration(),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildDotIndicator(),
          if (_currentPage == 2)
            GestureDetector(
              onTap: _onNext,
              child: Container(
                width: 160,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Get Started',
                      style: AppTextStyles.buttonText.copyWith(color: AppColors.primaryWhite),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: AppColors.primaryWhite, size: 20),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _onNext,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.primaryPurple,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward, color: AppColors.primaryWhite, size: 24),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator() {
    return Row(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(right: 8),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index ? AppColors.primaryPurple : AppColors.primaryBlack.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
