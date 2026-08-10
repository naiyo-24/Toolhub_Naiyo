import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/neo_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BusinessLoginScreen extends ConsumerStatefulWidget {
  const BusinessLoginScreen({super.key});

  @override
  ConsumerState<BusinessLoginScreen> createState() =>
      _BusinessLoginScreenState();
}

class _BusinessLoginScreenState extends ConsumerState<BusinessLoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    bool success = false;
    try {
      success = await ref.read(authProvider.notifier).signInWithGoogle();
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error', style: AppTextStyles.bodyText.copyWith(color: Colors.white)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 10),
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      if (success) {
        final prefs = await SharedPreferences.getInstance();
        final needsProfile = prefs.getBool('needs_profile') ?? false;
        if (mounted) {
          if (needsProfile) {
            context.pushReplacement('/create-profile');
          } else {
            context.pushReplacement('/business-toolkit');
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed or was canceled.',
                style: AppTextStyles.bodyText.copyWith(color: Colors.white)),
            backgroundColor: AppColors.primaryBlack,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Neo-brutalist grid background
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: NeoCard(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(8),
                      borderRadius: 50,
                      onTap: () => context.pop(),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.black, size: 24),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: const NeoCard(
                            backgroundColor: AppColors.primaryPurple,
                            borderWidth: 4,
                            padding: EdgeInsets.all(32),
                            borderRadius: 100,
                            shadowOffset: Offset(8, 8),
                            child: Icon(
                              Icons.business_center_rounded,
                              size: 70,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),

                        NeoCard(
                          backgroundColor: AppColors.primaryYellow,
                          borderWidth: 4,
                          padding: const EdgeInsets.all(32),
                          shadowOffset: const Offset(8, 8),
                          child: Column(
                            children: [
                              Text(
                                'BUSINESS\nTOOLKIT',
                                style: AppTextStyles.heroTitle.copyWith(
                                  color: Colors.black,
                                  fontSize: 32,
                                  height: 1.1,
                                  letterSpacing: 2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                height: 4,
                                width: 60,
                                color: Colors.black,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Sign in to access powerful business management tools, analytics, and generators.',
                                style: AppTextStyles.bodyText.copyWith(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Neo-brutalist Button
                        NeoCard(
                          backgroundColor: Colors.white,
                          borderWidth: 4,
                          borderRadius: 16,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shadowOffset: const Offset(6, 6),
                          onTap: _isLoading ? null : _handleGoogleSignIn,
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 4,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.black),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.network(
                                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                                        height: 24,
                                        width: 24,
                                      ),
                                      const SizedBox(width: 16),
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'Continue with Google',
                                            style: AppTextStyles.toolCardTitle
                                                .copyWith(
                                              color: Colors.black,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FutureBuilder<PackageInfo>(
                          future: PackageInfo.fromPlatform(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return SelectableText(
                                'Signature: ${snapshot.data?.buildSignature}',
                                style: const TextStyle(color: Colors.black, fontSize: 10),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.03)
      ..strokeWidth = 2;

    const spacing = 30.0;

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw vertical lines
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
