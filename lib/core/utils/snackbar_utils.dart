import 'package:flutter/material.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';

class SnackbarUtils {
  static void showNeoSnackBar(
    BuildContext context, {
    required String message,
    IconData? icon,
    bool isError = false,
  }) {
    // Clean up the error message if it's a raw exception string
    String cleanMessage = message
        .replaceAll('Exception: ', '')
        .replaceAll('DioException [unknown]: ', '')
        .replaceAll('DioException: ', '');

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isError ? const Color(0xFFFEE2E2) : Colors.white, // Light red for errors
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isError ? Colors.red.shade800 : Colors.black, width: 2),
            boxShadow: [
              BoxShadow(
                color: isError ? Colors.red.withValues(alpha: 0.3) : Colors.black26,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon ?? (isError ? Icons.error_outline_rounded : Icons.handyman_rounded), 
                color: isError ? Colors.red.shade800 : Colors.black, 
                size: 24
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  cleanMessage,
                  style: AppTextStyles.bodyText.copyWith(
                    color: isError ? Colors.red.shade900 : Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
