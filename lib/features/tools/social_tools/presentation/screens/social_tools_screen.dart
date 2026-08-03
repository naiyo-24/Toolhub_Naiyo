import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/widgets/universal_tool_card.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';

class SocialToolsScreen extends StatefulWidget {
  const SocialToolsScreen({super.key});

  @override
  State<SocialToolsScreen> createState() => _SocialToolsScreenState();
}

class _SocialToolsScreenState extends State<SocialToolsScreen> {
  String _searchQuery = '';
  final bool _showAllTools = false;
  
  final List<Map<String, dynamic>> tools = [
      // {'title': 'Bio Generator', 'subtitle': 'AI Social bios', 'icon': Icons.person_add_alt_1_rounded, 'color': AppColors.primaryPink, 'actionText': 'Generate', 'isAi': true},
      // {'title': 'Username Gen', 'subtitle': 'Catchy AI names', 'icon': Icons.alternate_email_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Generate', 'isAi': true},
      // {'title': 'Caption Gen', 'subtitle': 'Engaging AI captions', 'icon': Icons.closed_caption_rounded, 'color': AppColors.primaryGreen, 'actionText': 'Generate', 'isAi': true},
      // {'title': 'Hashtag Gen', 'subtitle': 'Trending hashtags', 'icon': Icons.tag_rounded, 'color': AppColors.primaryYellow, 'actionText': 'Generate', 'isAi': true},
      {'title': 'Emoji Converter', 'subtitle': 'Text to emoji text', 'icon': Icons.emoji_emotions_rounded, 'color': AppColors.primaryPink, 'actionText': 'Convert', 'endpoint': '/emoji-converter', 'config': [
        {'key': 'text', 'label': 'Enter text', 'icon': Icons.text_fields}
      ]},
      {'title': 'Fancy Text', 'subtitle': 'Generate unicode text', 'icon': Icons.font_download_rounded, 'color': AppColors.primaryPurple, 'actionText': 'Generate', 'endpoint': '/fancy-text', 'config': [
        {'key': 'text', 'label': 'Enter text', 'icon': Icons.text_fields}
      ]},
      {'title': 'Text to Emoji', 'subtitle': 'Regional indicators', 'icon': Icons.flag_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Convert', 'endpoint': '/text-to-emoji', 'config': [
        {'key': 'text', 'label': 'Enter text', 'icon': Icons.text_fields}
      ]},
      {'title': 'Char Counter', 'subtitle': 'Count characters & words', 'icon': Icons.calculate_rounded, 'color': AppColors.primaryGreen, 'actionText': 'Count', 'endpoint': '/char-counter', 'config': [
        {'key': 'text', 'label': 'Enter text', 'icon': Icons.text_fields}
      ]},
  ];

  void _showComingSoon(BuildContext context) {
    SnackbarUtils.showNeoSnackBar(context, message: 'This AI feature is coming soon!');
  }

  @override
  Widget build(BuildContext context) {
    var filteredTools = tools.where((tool) {
      final title = (tool['title'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query);
    }).toList();

    if (_searchQuery.isEmpty && !_showAllTools) {
      filteredTools = filteredTools.where((tool) => tool['isAi'] != true).toList();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: filteredTools.length,
                      itemBuilder: (context, index) {
                        final tool = filteredTools[index];
                        return UniversalToolCard(
                          title: tool['title'] as String,
                          subtitle: tool['subtitle'] as String?,
                          color: tool['color'] as Color,
                          icon: tool['icon'] as IconData,
                          actionText: tool['actionText'] as String,
                          onTap: () {
                            if (tool['isAi'] == true) {
                              _showComingSoon(context);
                            } else {
                              context.push('/social-tools/tool', extra: tool);
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: NeoCard(
        backgroundColor: const Color(0xFFFFD9D9), // Light red/pink to match home screen color for Social Tools
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        borderRadius: 12,
        shadowOffset: const Offset(4, 4),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                  ],
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 18),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SOCIAL ',
                        style: AppTextStyles.heroTitle.copyWith(fontSize: 22, color: Colors.black),
                      ),
                      Text(
                        'TOOLS',
                        style: AppTextStyles.logoText.copyWith(fontSize: 22, color: AppColors.primaryRed, fontWeight: FontWeight.normal, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  Text(
                    'ENGAGEMENT UTILITIES',
                    style: AppTextStyles.caption.copyWith(fontSize: 9, letterSpacing: 2, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 42), // Balance out the back button width
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: NeoCard(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: const InputDecoration(
            hintText: 'Search social tools...',
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
