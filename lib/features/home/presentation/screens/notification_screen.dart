import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/providers/notification_provider.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              'Notifications',
              style: AppTextStyles.heroTitle.copyWith(fontSize: 24),
            ),
            leading: GestureDetector(
              onTap: () {
                ref.read(notificationProvider.notifier).markAllAsRead();
                context.pop();
              },
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
                  boxShadow: [
                    BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2)),
                  ],
                ),
                child: Icon(Icons.arrow_back_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
              ),
            ),
            actions: [
              if (notifications.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(notificationProvider.notifier).clearAll();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPink,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
                        boxShadow: [
                          BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2)),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Clear',
                          style: AppTextStyles.buttonText.copyWith(color: Theme.of(context).colorScheme.onSurface, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final isUnread = !notif.isRead;

                return NeoCard(
                  backgroundColor: isUnread ? AppColors.primaryBlue : Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.all(16),
                  borderRadius: 16,
                  shadowOffset: const Offset(4, 4),
                  onTap: () {
                    if (isUnread) {
                      ref.read(notificationProvider.notifier).markAsRead(notif.id);
                    }
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
                        ),
                        child: Icon(
                          Icons.notifications_active_rounded,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    notif.title,
                                    style: AppTextStyles.heroTitle.copyWith(
                                      fontSize: 16,
                                      color: isUnread ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (isUnread)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(left: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryYellow,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              notif.message,
                              style: AppTextStyles.bodyText.copyWith(
                                fontSize: 13,
                                color: isUnread ? Colors.white.withValues(alpha: 0.9) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatTime(notif.timestamp),
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 11,
                                color: isUnread ? Colors.white.withValues(alpha: 0.7) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3),
              boxShadow: [
                BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(4, 4)),
              ],
            ),
            child: const Icon(Icons.notifications_off_rounded, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            'All Caught Up!',
            style: AppTextStyles.heroTitle.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no new notifications.',
            style: AppTextStyles.bodyText.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1 && now.day == time.day) {
      return DateFormat.jm().format(time); // e.g. 5:30 PM
    } else if (difference.inDays < 2) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(time); // e.g. Oct 24, 2023
    }
  }
}
