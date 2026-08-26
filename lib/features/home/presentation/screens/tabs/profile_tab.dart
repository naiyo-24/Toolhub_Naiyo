import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/api/api_config.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tool_hub/features/auth/presentation/providers/auth_provider.dart';
import 'package:tool_hub/core/ads/banner_ad_widget.dart';

class ProfileTab extends ConsumerStatefulWidget {
  final VoidCallback onShowComingSoon;

  const ProfileTab({
    super.key,
    required this.onShowComingSoon,
  });

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  String _userName = 'User';
  String _userEmail = '';
  String _userPic = '';
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'User';
      if (_userName.isEmpty) _userName = 'User';
      _userEmail = prefs.getString('user_email') ?? '';
      String pic = prefs.getString('user_pic') ?? '';
      if (pic.isNotEmpty) {
        if (pic.contains('/uploads/')) {
          pic = pic.substring(pic.indexOf('/uploads/'));
        }
        if (!pic.startsWith('http')) {
          pic = '${ApiConfig.baseUrl}$pic';
        }
      }
      _userPic = pic;
    });
  }

  Future<void> _handleSignIn() async {
    setState(() => _isSigningIn = true);
    try {
      final success = await ref.read(authProvider.notifier).signInWithGoogle();
      if (success) {
        await _loadProfileData();
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(authProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      children: [
        _buildHeader(context),
        _buildProfileCard(context, isLoggedIn),
        // const SizedBox(height: 24),
        // _buildProBanner(context),

        const SizedBox(height: 32),
        Text('About', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildSettingsItem(context, 'Help & Support', Icons.help_outline_rounded, false, false, (_) => _showHelpSupportBottomSheet(context)),
        _buildSettingsItem(context, 'About Us', Icons.info_outline_rounded, false, false, (_) => context.push('/about')),
        _buildSettingsItem(context, 'Terms of Service', Icons.description_outlined, false, false, (_) => context.push('/terms')),
        _buildSettingsItem(context, 'Privacy Policy', Icons.privacy_tip_outlined, false, false, (_) => context.push('/privacy')),
        
        const SizedBox(height: 32),
        if (isLoggedIn)
          GestureDetector(
            onTap: () async {
              await ref.read(authProvider.notifier).signOut();
              setState(() {
                _userName = 'User';
                _userEmail = '';
                _userPic = '';
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryRed, width: 2),
                boxShadow: [
                  BoxShadow(color: AppColors.primaryRed.withValues(alpha: 0.3), offset: const Offset(3, 3), blurRadius: 0),
                ],
              ),
              child: Center(
                child: Text(
                  'Log Out',
                  style: AppTextStyles.buttonText.copyWith(color: AppColors.primaryRed),
                ),
              ),
            ),
          )
        else
          GestureDetector(
            onTap: _isSigningIn ? null : _handleSignIn,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryBlack, width: 2),
                boxShadow: const [
                  BoxShadow(color: AppColors.primaryBlack, offset: Offset(3, 3), blurRadius: 0),
                ],
              ),
              child: _isSigningIn
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                          height: 20,
                          width: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Sign In with Google',
                          style: AppTextStyles.buttonText.copyWith(color: AppColors.primaryBlack),
                        ),
                      ],
                    ),
            ),
          ),
        const SizedBox(height: 32),
        Center(
          child: Text(
            'Version 1.0.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 0),
          child: BannerAdWidget(),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Profile',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28, height: 1.1),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, bool isLoggedIn) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryYellow,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
              image: _userPic.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(_userPic),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _userPic.isEmpty
                ? Center(
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primaryBlack),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoggedIn ? _userName : 'Guest User',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 20),
                ),
                if (isLoggedIn && _userEmail.isNotEmpty)
                  Text(
                    _userEmail,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                if (!isLoggedIn)
                  Text(
                    'Sign in to sync your forms & business data',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSettingsItem(BuildContext context, String title, IconData icon, bool hasSwitch, bool switchValue, Function(bool) onChanged, {String? trailing}) {
    return GestureDetector(
      onTap: hasSwitch ? null : () => onChanged(false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
              ),
            ),
            if (trailing != null) ...[
              Text(
                trailing,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(width: 8),
            ],
            if (hasSwitch)
              Switch(
                value: switchValue,
                onChanged: onChanged,
                activeThumbColor: AppColors.primaryPurple,
              )
            else
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Theme.of(context).colorScheme.onSurface),
          ],
        ),
      ),
    );
  }

  void _showHelpSupportBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.primaryBlack, width: 3),
            boxShadow: const [
              BoxShadow(
                color: AppColors.primaryBlack,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlack,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Help & Support',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 24),
              _buildSupportItem(context, Icons.phone_rounded, 'Call Us', '6289171798', () => _launchUrl('tel:6289171798')),
              _buildSupportItem(context, Icons.email_rounded, 'Email', 'services.naiyo@gmail.com', () => _launchUrl('mailto:services.naiyo@gmail.com')),
              _buildSupportItem(context, Icons.location_on_rounded, 'Location', 'View on Maps', () => _launchUrl('https://maps.app.goo.gl/w2GXuQgySTzW33nZ8?g_st=aw', mode: LaunchMode.externalApplication)),
              _buildSupportItem(context, Icons.public_rounded, 'Website', 'naiyo24.com', () => _launchUrl('https://naiyo24.com/', mode: LaunchMode.externalApplication)),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSupportItem(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryBlack, width: 2),
          boxShadow: const [
            BoxShadow(color: AppColors.primaryBlack, offset: Offset(3, 3), blurRadius: 0),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryBlack, width: 1.5),
              ),
              child: Icon(icon, color: AppColors.primaryBlack, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primaryBlack, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString, {LaunchMode mode = LaunchMode.platformDefault}) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: mode)) {
      debugPrint('Could not launch $url');
    }
  }
}
