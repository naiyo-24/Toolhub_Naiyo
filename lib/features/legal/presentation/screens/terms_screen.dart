import 'package:flutter/material.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
          'Terms of Service',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(context, '1. Acceptance of Terms', 'By accessing and using Tool Hub, you accept and agree to be bound by the terms and provision of this agreement. In addition, when using these particular services, you shall be subject to any posted guidelines or rules applicable to such services.'),
            _buildSection(context, '2. Description of Service', 'Tool Hub provides users with access to a rich collection of tools and resources (the "Service"). You understand and agree that the Service is provided "AS-IS" and that Tool Hub assumes no responsibility for the timeliness, deletion, mis-delivery or failure to store any user communications or personalization settings.'),
            _buildSection(context, '3. User Conduct', "You agree to not use the Service to upload, post, email, transmit or otherwise make available any content that is unlawful, harmful, threatening, abusive, harassing, tortious, defamatory, vulgar, obscene, libelous, invasive of another's privacy, hateful, or racially, ethnically or otherwise objectionable."),
            _buildSection(context, '4. Modifications to Service', 'Tool Hub reserves the right at any time and from time to time to modify or discontinue, temporarily or permanently, the Service (or any part thereof) with or without notice. You agree that Tool Hub shall not be liable to you or to any third party for any modification, suspension or discontinuance of the Service.'),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface,
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.sectionTitle.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: AppTextStyles.bodyText.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
