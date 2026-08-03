import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';

class PermissionDisclosureUtils {
  /// Shows a standard disclosure bottom sheet explaining why a permission is needed.
  /// Returns `true` if the user clicks "Continue" (meaning they agree to see the native prompt),
  /// and `false` if they cancel or dismiss the sheet.
  static Future<bool> showPermissionDisclosure(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    Color? color,
  }) async {
    final themeColor = color ?? Colors.blue;

    final result = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: themeColor),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: AppTextStyles.bodyText.copyWith(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    return result == true;
  }

  /// Helper to check and request permission with a disclosure if it's not already granted.
  static Future<bool> requestWithDisclosure(
    BuildContext context, {
    required Permission permission,
    required String title,
    required String description,
    required IconData icon,
    Color? color,
  }) async {
    final status = await permission.status;

    if (status.isGranted) {
      return true; // Already granted
    }

    if (status.isPermanentlyDenied) {
      // If permanently denied, we can either return false or open settings.
      if (context.mounted) {
        bool? goToSettings = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Permission Required'),
            content: Text('$title is permanently denied. Please enable it in app settings.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );

        if (goToSettings == true) {
          await openAppSettings();
        }
      }
      return false; 
    }

    // Need to ask for permission. Show disclosure first.
    if (!context.mounted) return false;

    final agreed = await showPermissionDisclosure(
      context,
      title: title,
      description: description,
      icon: icon,
      color: color,
    );

    if (agreed) {
      final requestStatus = await permission.request();
      return requestStatus.isGranted;
    }

    return false;
  }
}
