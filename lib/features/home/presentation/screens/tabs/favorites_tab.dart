import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/tool_card.dart';
import 'package:tool_hub/core/utils/dialog_utils.dart';
import 'package:tool_hub/features/auth/presentation/providers/auth_provider.dart';
import 'package:tool_hub/features/home/presentation/providers/favorites_provider.dart';

class FavoritesTab extends ConsumerWidget {
  final VoidCallback onShowComingSoon;

  const FavoritesTab({
    super.key,
    required this.onShowComingSoon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteTools = ref.watch(favoritesProvider);

    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: favoriteTools.isEmpty
              ? _buildEmptyState(context)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    const crossAxisCount = 2;
                    final availableWidth = constraints.maxWidth - 40; // 20 padding on each side
                    final itemWidth = (availableWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
                    const itemHeight = 120.0;
                    final childAspectRatio = itemWidth / itemHeight;

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 180),
                      itemCount: favoriteTools.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        final tool = favoriteTools[index];
                    return ToolCard(
                      title: tool.title,
                      subtitle: tool.subtitle,
                      backgroundColor: tool.bgColor,
                      icon: tool.icon,
                      iconColor: tool.iconColor,
                      onTap: () {
                        final t = tool.title;
                        if (t.contains('Daily')) {
                          context.push('/daily-utility');
                        } else if (t.contains('Internet Tools')) {
                          context.push('/internet-tools');
                        } else if (t.contains('File')) {
                          context.push('/file-sharing');
                        } else if (t.contains('AI')) {
                          DialogUtils.showAIBottomSheet(context);
                        } else if (t.contains('Student')) {
                          context.push('/student-toolkit');
                        } else if (t.contains('Docu')) {
                          context.push('/docu-forge');
                        } else if (t.contains('Business')) {
                          if (ref.read(authProvider)) {
                            context.push('/business-toolkit');
                          } else {
                            context.push('/business-login');
                          }
                        } else if (t.contains('Finance')) {
                          context.push('/finance-tools');
                        } else if (t.contains('Social')) {
                          context.push('/social-tools');
                        } else if (t.contains('Health')) {
                          context.push('/health-lifestyle');
                        } else if (t.contains('Productivity')) {
                          context.push('/productivity');
                        } else if (t.contains('Travel')) {
                          context.push('/travel-tools');
                        } else if (t.contains('Form')) {
                          context.push('/form-builder');
                        } else {
                          onShowComingSoon();
                        }
                      },
                    );
                  },
                );
              },
            ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Saved Tools',
            style: AppTextStyles.heroTitle.copyWith(fontSize: 28, height: 1.1),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
              boxShadow: [
                BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2), blurRadius: 0),
              ],
            ),
            child: Icon(Icons.star_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 120.0), // Offset for the bottom nav bar
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star_border_rounded, size: 64, color: AppColors.primaryYellow),
          const SizedBox(height: 16),
          Text(
            'No Favorites Yet',
            style: AppTextStyles.heroTitle.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          const Text(
            'Star your most used tools\nfor quick access here.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyText,
          ),
        ],
      ),
      ),
    );
  }
}
