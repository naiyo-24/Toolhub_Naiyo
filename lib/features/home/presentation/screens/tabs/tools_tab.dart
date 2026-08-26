import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/tool_card.dart';
import 'package:tool_hub/core/utils/dialog_utils.dart';
import 'package:tool_hub/features/auth/presentation/providers/auth_provider.dart';
import 'package:tool_hub/core/ads/banner_ad_widget.dart';

class ToolsTab extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> allTools;
  final VoidCallback onShowComingSoon;

  const ToolsTab({
    super.key,
    required this.allTools,
    required this.onShowComingSoon,
  });

  @override
  ConsumerState<ToolsTab> createState() => _ToolsTabState();
}

class _ToolsTabState extends ConsumerState<ToolsTab> {
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    'All',
    'Utilities',
    'Business',
    'Lifestyle',
    'Productivity',
  ];
  @override
  Widget build(BuildContext context) {
    final selectedCategory = _categories[_selectedCategoryIndex];
    
    final filteredTools = widget.allTools.where((tool) {
      if (selectedCategory == 'All') return true;
      
      final title = tool['title'].toString();
      
      if (selectedCategory == 'Utilities') {
        return title.contains('Utility') || title.contains('Internet') || title.contains('File') || title.contains('AI');
      } else if (selectedCategory == 'Business') {
        return title.contains('Finance') || title.contains('Business') || title.contains('DocuForge') || title.contains('Form') || title.contains('LoanDesk');
      } else if (selectedCategory == 'Lifestyle') {
        return title.contains('Health') || title.contains('Social') || title.contains('Travel');
      } else if (selectedCategory == 'Productivity') {
        return title.contains('Productivity') || title.contains('Student');
      }
      
      return true;
    }).toList();

    return Column(
      children: [
        _buildHeader(),
        _buildSearchBar(),
        _buildCategories(),
        Expanded(
          child: filteredTools.isEmpty
              ? Center(
                  child: Text(
                    'No tools available',
                    style: AppTextStyles.bodyText.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    const crossAxisCount = 3;
                    // constraints.maxWidth minus padding (20 on each side) is handled if LayoutBuilder is inside padding, 
                    // but here GridView has padding: const EdgeInsets.all(20), so constraints.maxWidth is the full width.
                    // Let's account for padding in width calculation.
                    final availableWidth = constraints.maxWidth - 40; 
                    final itemWidth = (availableWidth - (crossAxisCount - 1) * 12) / crossAxisCount;
                    const itemHeight = 135.0; // Fixed height to ensure content fits
                    final childAspectRatio = itemWidth / itemHeight;

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 180),
                      itemCount: filteredTools.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: childAspectRatio,
                      ),
                  itemBuilder: (context, index) {
                    final tool = filteredTools[index];
                    return ToolCard(
                      title: tool['title'] as String,
                      subtitle: tool['subtitle'] as String,
                      backgroundColor: tool['color'] as Color,
                      icon: tool['icon'] as IconData,
                      iconColor: tool['iconColor'] as Color,
                      onTap: () {
                        final t = tool['title'].toString();
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
                        } else if (t.contains('LoanDesk')) {
                          context.push('/loandesk/login');
                        } else {
                          widget.onShowComingSoon();
                        }
                      },
                    );
                  },
                );
              },
            ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: BannerAdWidget(),
        ),
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tools Browser',
            style: AppTextStyles.heroTitle.copyWith(fontSize: 28, height: 1.1),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
              boxShadow: [
                BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2), blurRadius: 0),
              ],
            ),
            child: Icon(Icons.filter_list_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          context.push('/search');
        },
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(4, 4), blurRadius: 0),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), size: 22),
              ),
              Expanded(
                child: Text(
                  'Search 20+ tools...',
                  style: AppTextStyles.bodyText.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 15),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.surface, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 20, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryPurple : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                boxShadow: isSelected
                    ? [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2), blurRadius: 0)]
                    : [],
              ),
              child: Center(
                child: Text(
                  _categories[index],
                  style: AppTextStyles.buttonText.copyWith(
                    color: isSelected ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
