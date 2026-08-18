import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/loandesk_theme.dart';
import '../../widgets/neo_button.dart';
import '../../widgets/neo_card.dart';
import '../../providers/auth_provider.dart';

class LoanDeskLoginScreen extends ConsumerWidget {
  const LoanDeskLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.user != null && (previous?.user == null || previous!.user!.isProfileComplete != next.user!.isProfileComplete)) {
        if (next.user!.isProfileComplete) {
          context.pushReplacement('/loandesk/dashboard');
        } else {
          context.pushReplacement('/loandesk/onboarding');
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authState.user != null) {
        if (authState.user!.isProfileComplete) {
          context.pushReplacement('/loandesk/dashboard');
        } else {
          context.pushReplacement('/loandesk/onboarding');
        }
      }
    });

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: Stack(
        children: [
          // Eye-catchy Vibrant Mesh Background
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: size.width,
              height: size.width,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: LoanDeskTheme.primaryYellow,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: size.width,
              height: size.width,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: LoanDeskTheme.primaryPink,
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.3,
            left: -100,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: LoanDeskTheme.primaryBlue,
              ),
            ),
          ),
          
          // Heavy Blur to create the Premium Mesh Gradient effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Neo-Brutalist Back Button
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: InkWell(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: LoanDeskTheme.primaryWhite,
                          shape: BoxShape.circle,
                          border: Border.all(color: LoanDeskTheme.primaryBlack, width: 3),
                          boxShadow: const [BoxShadow(color: LoanDeskTheme.primaryBlack, offset: Offset(3, 3))],
                        ),
                        child: const Icon(Icons.arrow_back, color: LoanDeskTheme.primaryBlack, size: 24),
                      ),
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Pure Neo-Brutalism Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: NeoCard(
                    backgroundColor: LoanDeskTheme.primaryWhite,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon Badge
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: LoanDeskTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: LoanDeskTheme.primaryBlack, width: 3),
                            boxShadow: const [
                              BoxShadow(color: LoanDeskTheme.primaryBlack, offset: Offset(4, 4)),
                            ],
                          ),
                          child: const Icon(
                            Icons.account_balance_rounded,
                            size: 48,
                            color: LoanDeskTheme.primaryWhite,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Typography
                        const Text(
                          'LOAN DESK',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: LoanDeskTheme.primaryBlack,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: LoanDeskTheme.primaryPink,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: LoanDeskTheme.primaryBlack, width: 2),
                          ),
                          child: const Text(
                            'BANKER WORKSPACE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: LoanDeskTheme.primaryWhite,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        const Text(
                          'Secure access to your professional loan processing environment.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Auth Error
                        if (authState.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: LoanDeskTheme.primaryRed,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: LoanDeskTheme.primaryBlack, width: 2),
                              ),
                              child: Text(
                                authState.error!,
                                style: const TextStyle(
                                  color: LoanDeskTheme.primaryWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        
                        // Google Login Button
                        if (authState.isLoading)
                          const Center(
                            child: CircularProgressIndicator(
                              color: LoanDeskTheme.primaryBlack,
                              strokeWidth: 4,
                            ),
                          )
                        else
                          NeoButton(
                            text: 'CONTINUE WITH GOOGLE',
                            isFullWidth: true,
                            color: LoanDeskTheme.primaryYellow,
                            imageAsset: 'assets/logos/google_logo.png',
                            onPressed: () {
                              ref.read(authProvider.notifier).signInWithGoogle();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
