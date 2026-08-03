import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/features/home/presentation/providers/favorites_provider.dart';

class UniversalToolCard extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final String actionText;
  final VoidCallback onTap;
  final bool isCircularIcon;

  const UniversalToolCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.actionText,
    required this.onTap,
    this.isCircularIcon = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoritesProvider.notifier).isFavorite(title);
    ref.watch(favoritesProvider);

    return GestureDetector(
      onTap: onTap,
      child: NeoCard(
        backgroundColor: color,
        padding: const EdgeInsets.all(12),
        borderRadius: 16,
        shadowOffset: const Offset(3, 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCircularIcon)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: Icon(icon, color: Colors.black, size: 20),
                  )
                else
                  Icon(icon, color: Colors.black, size: 24),
                GestureDetector(
                  onTap: () {
                    ref.read(favoritesProvider.notifier).toggleFavorite(
                      title,
                      subtitle ?? '',
                      icon,
                      color,
                      Colors.black,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 20,
                      color: isFavorite ? const Color(0xFFFFB300) : Colors.black45,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.toolCardTitle.copyWith(fontSize: 14, color: Colors.black, height: 1.1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        subtitle!,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 9,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black, width: 1.5),
                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        actionText,
                        style: AppTextStyles.buttonText.copyWith(fontSize: 9, color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, size: 10, color: Colors.black),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
