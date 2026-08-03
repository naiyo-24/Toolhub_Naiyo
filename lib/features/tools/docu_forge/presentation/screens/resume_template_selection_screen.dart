import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import '../../data/resume_model.dart';

class ResumeTemplateSelectionScreen extends StatelessWidget {
  final ResumeData resumeData;

  const ResumeTemplateSelectionScreen({super.key, required this.resumeData});

  @override
  Widget build(BuildContext context) {
    final templates = [
      {'id': 'modern', 'name': 'Modern Neo-Brutalist', 'color': AppColors.primaryYellow, 'desc': 'Bold colors, high contrast, perfect for creatives.'},
      {'id': 'minimal', 'name': 'Minimalist', 'color': AppColors.primaryBlue, 'desc': 'Clean, elegant, lots of whitespace. Great for tech roles.'},
      {'id': 'classic', 'name': 'Classic Professional', 'color': AppColors.primaryPink, 'desc': 'Traditional layout, ATS-friendly. Best for finance/law.'},
      {'id': 'creative', 'name': 'Creative Studio', 'color': AppColors.primaryGreen, 'desc': 'Two-column layout, eye-catching design for designers.'},
      {'id': 'executive', 'name': 'Executive', 'color': AppColors.primaryOrange, 'desc': 'Highly formal and centered. For senior leadership.'},
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        elevation: 0,
        centerTitle: true,
        title: Text('Select Template', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final t = templates[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: GestureDetector(
              onTap: () {
                context.push('/resume-preview', extra: {
                  'resumeData': resumeData,
                  'templateId': t['id'],
                });
              },
              child: NeoCard(
                backgroundColor: t['color'] as Color,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                    const SizedBox(height: 8),
                    Text(t['desc'] as String, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Use this Template ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Icon(Icons.arrow_forward_rounded, color: Colors.black),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
