import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/features/home/presentation/providers/history_provider.dart';
import 'package:tool_hub/core/utils/dialog_utils.dart';
import 'package:tool_hub/features/auth/presentation/providers/auth_provider.dart';

class HistoryTab extends ConsumerWidget {
  final VoidCallback onShowComingSoon;

  const HistoryTab({
    super.key,
    required this.onShowComingSoon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, ref),
        Expanded(
          child: history.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 180),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return _buildHistoryItem(
                      context,
                      item.title,
                      'Opened ${formatTimeAgo(item.timestamp)}',
                      item.icon,
                      item.bgColor,
                      item.iconColor,
                      () {
                        final t = item.title;
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
                      }
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'History',
            style: AppTextStyles.heroTitle.copyWith(fontSize: 28, height: 1.1),
          ),
          GestureDetector(
            onTap: () {
              ref.read(historyProvider.notifier).clearHistory();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                boxShadow: [
                  BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2), blurRadius: 0),
                ],
              ),
              child: Text(
                'Clear',
                style: AppTextStyles.buttonText.copyWith(fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 120.0), // Offset for bottom nav bar
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_rounded, size: 64, color: AppColors.primaryPurple),
            const SizedBox(height: 16),
            Text(
              'No History Found',
              style: AppTextStyles.heroTitle.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              'Your recently opened tools\nwill appear here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyText.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, String title, String subtitle, IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
          boxShadow: [
            BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(3, 3), blurRadius: 0),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.toolCardTitle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Theme.of(context).colorScheme.onSurface),
          ],
        ),
      ),
    );
  }
}
