import 'package:flutter/material.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';

// Helper widget for a neo-brutalism block used in illustrations
class _HexBlock extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Color iconColor;
  final double size;
  final double iconSize;

  const _HexBlock({
    required this.color,
    required this.icon,
    required this.iconColor,
    this.size = 100,
    this.iconSize = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBlack, width: 3),
        boxShadow: const [
          BoxShadow(
              color: AppColors.primaryBlack,
              offset: Offset(5, 5),
              blurRadius: 0),
        ],
      ),
      child: Center(
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}

class WelcomeIllustration extends StatelessWidget {
  const WelcomeIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background dotted pattern can be added if needed, but keeping it clean
          Positioned(
            top: 20,
            child: Transform.rotate(
              angle: 0.1,
              child: const _HexBlock(
                color: AppColors.primaryPurple,
                icon: Icons.bolt,
                iconColor: AppColors.primaryWhite,
                size: 120,
                iconSize: 60,
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 50,
            child: Transform.rotate(
              angle: -0.15,
              child: const _HexBlock(
                color: AppColors.primaryYellow,
                icon: Icons.settings,
                iconColor: AppColors.primaryBlack,
                size: 110,
                iconSize: 55,
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            right: 50,
            child: Transform.rotate(
              angle: 0.05,
              child: const _HexBlock(
                color: AppColors.primaryBlack,
                icon: Icons.bar_chart,
                iconColor: AppColors.primaryWhite,
                size: 110,
                iconSize: 55,
              ),
            ),
          ),
          // Small decorative elements
          const Positioned(
              top: 50,
              left: 40,
              child:
                  Icon(Icons.close, color: AppColors.primaryYellow, size: 20)),
          Positioned(
              top: 100,
              right: 30,
              child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                      color: AppColors.primaryPurple,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: AppColors.primaryBlack, width: 2)))),
          const Positioned(
              bottom: 150,
              right: 20,
              child:
                  Icon(Icons.close, color: AppColors.primaryYellow, size: 24)),
          const Positioned(
              bottom: 120,
              left: 30,
              child:
                  Icon(Icons.close, color: AppColors.primaryYellow, size: 16)),
        ],
      ),
    );
  }
}

class PhoneGridIllustration extends StatelessWidget {
  const PhoneGridIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = [
      {'color': const Color(0xFF6C3BFF), 'icon': Icons.grid_view_rounded},
      {'color': const Color(0xFF111111), 'icon': Icons.link_rounded},
      {
        'color': const Color(0xFF4ADE80),
        'icon': Icons.insert_drive_file_outlined
      },
      {'color': const Color(0xFFFF8C00), 'icon': Icons.smart_toy_outlined},
      {'color': const Color(0xFFFF5AA5), 'icon': Icons.school_outlined},
      {'color': const Color(0xFF4D7CFE), 'icon': Icons.picture_as_pdf_outlined},
      {'color': const Color(0xFFFFD54A), 'icon': Icons.checklist_rounded},
      {
        'color': const Color(0xFF6C3BFF),
        'icon': Icons.business_center_outlined
      },
    ];

    return Container(
      width: 220,
      height: 380,
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.primaryBlack, width: 4),
        boxShadow: const [
          BoxShadow(
              color: AppColors.primaryBlack,
              offset: Offset(8, 8),
              blurRadius: 0),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          // Phone speaker
          Container(
            width: 40,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.primaryBlack,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 8,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final tool = tools[index];
                return Container(
                  decoration: BoxDecoration(
                    color: tool['color'] as Color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryBlack, width: 2),
                    boxShadow: const [
                      BoxShadow(
                          color: AppColors.primaryBlack,
                          offset: Offset(3, 3),
                          blurRadius: 0),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      tool['icon'] as IconData,
                      color: AppColors.primaryWhite,
                      size: 28,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SecurityShieldIllustration extends StatelessWidget {
  const SecurityShieldIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background dotted pattern can be added if needed
          // Main Shield
          Positioned(
            left: 40,
            top: 60,
            child: Transform.rotate(
              angle: -0.1,
              child: Container(
                width: 130,
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(60),
                    bottomRight: Radius.circular(60),
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  border: Border.all(color: AppColors.primaryBlack, width: 4),
                  boxShadow: const [
                    BoxShadow(
                        color: AppColors.primaryBlack,
                        offset: Offset(6, 6),
                        blurRadius: 0),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.check_rounded,
                      color: AppColors.primaryWhite, size: 70),
                ),
              ),
            ),
          ),

          // Tags
          Positioned(
            right: 30,
            top: 50,
            child: _buildFeatureTag(
                '100% Secure', Icons.lock, AppColors.primaryWhite),
          ),
          Positioned(
            right: 40,
            top: 120,
            child: _buildFeatureTag(
                'Super Fast', Icons.bolt, AppColors.primaryYellow),
          ),
          Positioned(
            right: 50,
            top: 190,
            child: _buildFeatureTag(
                'Always Updated', Icons.autorenew, const Color(0xFFD9FFEB)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTag(String text, IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlack, width: 3),
        boxShadow: const [
          BoxShadow(
              color: AppColors.primaryBlack,
              offset: Offset(4, 4),
              blurRadius: 0),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryBlack, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTextStyles.toolCardTitle.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
