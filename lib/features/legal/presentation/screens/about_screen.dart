import 'package:flutter/material.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String urlString, {LaunchMode mode = LaunchMode.platformDefault}) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: mode)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'About Us',
          style: AppTextStyles.sectionTitle.copyWith(color: Theme.of(context).colorScheme.onSurface, fontSize: 20),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            color: Theme.of(context).colorScheme.onSurface,
            height: 2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAboutCard(context),
            const SizedBox(height: 24),
            _buildNaiyoCard(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE4D9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlack, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.primaryBlack,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/logos/toolhub_logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 32),
              ),
              const SizedBox(width: 12),
              const Text('Tool Hub', style: AppTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Aim & Vision',
            style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Our aim is to provide a comprehensive, all-in-one toolkit that empowers professionals, students, and everyday users to maximize their productivity. We strive to simplify complex daily tasks through accessible and intuitive tools.',
            style: AppTextStyles.bodyText.copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          Text(
            'The Product',
            style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Tool Hub is a highly optimized, neo-brutalist utility application offering a vast collection of tools ranging from daily utilities and secure file sharing to AI meeting summarization and student career tools. It is your single destination for everyday digital empowerment.',
            style: AppTextStyles.bodyText.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildNaiyoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlack, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.primaryBlack,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Powered by',
            style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryBlack.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryBlack, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/logos/naiyo24_logo.jpeg',
                height: 100,
                width: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Naiyo24 Pvt Ltd',
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: 24),
          _buildContactItem(Icons.phone_rounded, 'Call Us', '6289171798', () => _launchUrl('tel:6289171798')),
          const SizedBox(height: 12),
          _buildContactItem(Icons.email_rounded, 'Email', 'services.naiyo@gmail.com', () => _launchUrl('mailto:services.naiyo@gmail.com')),
          const SizedBox(height: 12),
          _buildContactItem(Icons.location_on_rounded, 'Location', 'View on Maps', () => _launchUrl('https://maps.app.goo.gl/w2GXuQgySTzW33nZ8?g_st=aw', mode: LaunchMode.externalApplication)),
          const SizedBox(height: 12),
          _buildContactItem(Icons.public_rounded, 'Website', 'naiyo24.com', () => _launchUrl('https://naiyo24.com/', mode: LaunchMode.externalApplication)),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6D9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryBlack, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryBlack, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primaryBlack, size: 14),
          ],
        ),
      ),
    );
  }
}
