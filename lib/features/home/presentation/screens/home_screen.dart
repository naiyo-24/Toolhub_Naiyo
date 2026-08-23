import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/features/auth/presentation/providers/auth_provider.dart';
import 'package:tool_hub/features/home/presentation/screens/tabs/tools_tab.dart';
import 'package:tool_hub/features/home/presentation/screens/tabs/favorites_tab.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';
import 'package:tool_hub/features/home/presentation/screens/tabs/history_tab.dart';
import 'package:tool_hub/features/home/presentation/screens/tabs/profile_tab.dart';
import 'package:tool_hub/features/home/presentation/providers/history_provider.dart';
import 'package:tool_hub/core/utils/dialog_utils.dart';
import 'package:tool_hub/core/providers/notification_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _userName = '';

  final List<Map<String, dynamic>> _allTools = [
    {'title': 'Daily\nUtility', 'subtitle': '8+ Tools', 'color': const Color(0xFFE4D9FF), 'icon': Icons.grid_view_rounded, 'iconColor': AppColors.primaryPurple},
    {'title': 'Internet Tools', 'subtitle': 'Network Utilities', 'color': const Color(0xFFD9EDFF), 'icon': Icons.public_rounded, 'iconColor': AppColors.primaryBlue},
    {'title': 'File\nTools', 'subtitle': 'File Utilities', 'color': const Color(0xFFD9FFEB), 'icon': Icons.folder_rounded, 'iconColor': AppColors.primaryGreen},
    {'title': 'AI\nTools', 'subtitle': 'AI Powered', 'color': const Color(0xFFFFE8D9), 'icon': Icons.smart_toy_outlined, 'iconColor': const Color(0xFFFF8C00)},
    {'title': 'Student\nToolkit', 'subtitle': '15+ Tools', 'color': const Color(0xFFFFD9EA), 'icon': Icons.school_outlined, 'iconColor': AppColors.primaryPink},
    {'title': 'DocuForge', 'subtitle': 'PDF Tools', 'color': const Color(0xFFD9F9FF), 'icon': Icons.picture_as_pdf_outlined, 'iconColor': const Color(0xFF00A2C7)},
    {'title': 'Finance\nTools', 'subtitle': 'Money Manager', 'color': const Color(0xFFFFF6D9), 'icon': Icons.account_balance_rounded, 'iconColor': AppColors.primaryYellow},
    {'title': 'Business\nToolkit', 'subtitle': '15+ Tools', 'color': const Color(0xFFE9D9FF), 'icon': Icons.business_center_outlined, 'iconColor': const Color(0xFF8B00FF)},
    {'title': 'Social\nTools', 'subtitle': 'Social Media', 'color': const Color(0xFFFFD9D9), 'icon': Icons.connect_without_contact_rounded, 'iconColor': AppColors.primaryRed},
    {'title': 'Health &\nLifestyle', 'subtitle': 'Wellness', 'color': const Color(0xFFD9FFED), 'icon': Icons.favorite_border_rounded, 'iconColor': const Color(0xFF00C853)},
    {'title': 'Productivity', 'subtitle': 'Get things done', 'color': const Color(0xFFFFEBD9), 'icon': Icons.access_time_filled_rounded, 'iconColor': const Color(0xFFFF9800)},
    {'title': 'Travel\nTools', 'subtitle': 'Explore the world', 'color': const Color(0xFFD9F2FF), 'icon': Icons.flight_takeoff_rounded, 'iconColor': const Color(0xFF00B0FF)},
    {'title': 'Form\nBuilder', 'subtitle': 'Custom forms', 'color': const Color(0xFFF2D9FF), 'icon': Icons.dynamic_form_rounded, 'iconColor': const Color(0xFFD500F9)},
    {'title': 'LoanDesk', 'subtitle': 'Banker Workspace', 'color': const Color(0xFFFFD166), 'icon': Icons.account_balance, 'iconColor': const Color(0xFF000000)},
  ];

  late List<Map<String, dynamic>> _randomTopTools;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _pageController = PageController(initialPage: _currentIndex);
    _randomTopTools = List.from(_allTools)..shuffle();
    _randomTopTools = _randomTopTools.take(8).toList();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? '';
      final isLoggedIn = prefs.getBool('is_business_logged_in') ?? false;
      if (_userName.isEmpty && isLoggedIn) {
        _userName = 'User';
      } else if (!isLoggedIn) {
        _userName = '';
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToTab(int index) {
    if (_currentIndex == index) return;
    
    int currentPage = _pageController.hasClients ? _pageController.page!.round() : _currentIndex;
    
    setState(() {
      _currentIndex = index;
    });

    if ((currentPage - index).abs() > 1) {
      _pageController.jumpToPage(index > currentPage ? index - 1 : index + 1);
    }
    
    // We use a slight delay if we just jumped, but flutter handles it synchronously enough
    // that it usually works perfectly to jump then animate.
    // However, to ensure smooth animation after jump, we use animateToPage.
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showComingSoon() {
    SnackbarUtils.showNeoSnackBar(context, message: 'Feature coming soon!');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      _loadUserData();
    });

    return PopScope(
      canPop: false,
      // ignore: deprecated_member_use
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        if (_currentIndex != 0) {
          _navigateToTab(0);
          return;
        }

        final bool shouldPop = await _showExitDialog() ?? false;
        if (shouldPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: _buildBody(),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(6, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.exit_to_app_rounded, size: 48, color: Colors.black),
                const SizedBox(height: 16),
                Text(
                  'Leaving so soon?',
                  style: AppTextStyles.sectionTitle.copyWith(color: Colors.black, fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to exit Tool Hub?',
                  style: AppTextStyles.bodyText.copyWith(color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Stay',
                            style: AppTextStyles.buttonText.copyWith(color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Leave',
                            style: AppTextStyles.buttonText.copyWith(color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      children: [
        _buildHomeTab(),
        ToolsTab(allTools: _allTools, onShowComingSoon: _showComingSoon),
        FavoritesTab(onShowComingSoon: _showComingSoon),
        HistoryTab(onShowComingSoon: _showComingSoon),
        ProfileTab(onShowComingSoon: _showComingSoon),
      ],
    );
  }

  Future<void> _refreshHome() async {
    setState(() {
      _randomTopTools = List.from(_allTools)..shuffle();
      _randomTopTools = _randomTopTools.take(8).toList();
    });
    // Slight delay to show the refresh animation
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _refreshHome,
      color: AppColors.primaryPurple,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: _buildAppBar(),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildGreeting(),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildSearchBar(),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildProductivityBanner(),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildSectionHeader('Top Tools', 'View All ›'),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildTopToolsGrid(),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildSectionHeader('Quick Actions', ''),
        ),
        const SizedBox(height: 14),
        _buildQuickActionsRow(),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildSectionHeader('Recently Used', 'See History ›'),
        ),
        const SizedBox(height: 14),
        _buildRecentlyUsed(),
        const SizedBox(height: 180),
      ],
    ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/logos/toolhub_logo.png',
              height: 48,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image, size: 48);
              },
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('TOOL', style: AppTextStyles.logoText.copyWith(fontSize: 26, height: 1.0, color: Theme.of(context).colorScheme.onSurface)),
                Text('HUB', style: AppTextStyles.logoText.copyWith(fontSize: 26, height: 1.0, color: AppColors.primaryPurple)),
              ],
            ),
          ],
        ),
        Row(
          children: [
            Consumer(
              builder: (context, ref, child) {
                final unreadCount = ref.watch(notificationProvider.notifier).unreadCount;
                // Watch to rebuild when it changes
                ref.watch(notificationProvider);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    NeoCard(
                      padding: const EdgeInsets.all(10),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      borderRadius: 12,
                      shadowOffset: const Offset(3, 3),
                      onTap: () {
                        context.push('/notifications');
                      },
                      child: Icon(Icons.notifications_none_rounded, color: Theme.of(context).colorScheme.onSurface, size: 22),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple,
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 9 ? '9+' : unreadCount.toString(),
                              style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.surface, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning,',
          style: AppTextStyles.bodyText.copyWith(
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              _userName.isNotEmpty ? '${_userName.split(' ').first}! ' : 'Scholar! ',
              style: AppTextStyles.heroTitle.copyWith(
                fontSize: 26,
                letterSpacing: -0.5,
              ),
            ),
            const Text('👋', style: TextStyle(fontSize: 24)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'All your tools, in one place.',
          style: AppTextStyles.bodyText.copyWith(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
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
                'Search any tool...',
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
    );
  }

  Widget _buildProductivityBanner() {
    return GestureDetector(
      onTap: _showComingSoon,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryPurple,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3),
          boxShadow: [
            BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(5, 5), blurRadius: 0),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 22, 16, 22),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GET MORE',
                    style: AppTextStyles.heroTitle.copyWith(
                      fontSize: 28,
                      color: Theme.of(context).colorScheme.surface,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'DONE.',
                    style: AppTextStyles.heroTitle.copyWith(
                      fontSize: 28,
                      color: AppColors.primaryYellow,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Powerful tools to simplify\nyour everyday tasks.',
                    style: AppTextStyles.bodyText.copyWith(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      _navigateToTab(1);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
                        boxShadow: [
                          BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(3, 3), blurRadius: 0),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Explore Tools',
                            style: AppTextStyles.buttonText.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_forward, size: 16, color: Theme.of(context).colorScheme.onSurface),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 3D hexagon blocks illustration
            Column(
              children: [
                _buildHexBlock(AppColors.primaryYellow, Icons.bolt, Theme.of(context).colorScheme.onSurface),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildHexBlock(AppColors.primaryPink, Icons.settings, Theme.of(context).colorScheme.surface),
                    const SizedBox(width: 4),
                    _buildHexBlock(AppColors.primaryBlue, Icons.bar_chart, Theme.of(context).colorScheme.surface),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHexBlock(Color color, IconData icon, Color iconColor) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Icon(icon, color: iconColor, size: 28),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: AppTextStyles.sectionTitle.copyWith(
            fontSize: 18,
          ),
        ),
        if (action.isNotEmpty)
          GestureDetector(
            onTap: () {
              if (action.contains('All')) {
                _navigateToTab(1);
              } else if (action.contains('History')) {
                _navigateToTab(3);
              }
            },
            child: Text(
              action,
              style: AppTextStyles.buttonText.copyWith(
                fontSize: 13,
                color: AppColors.primaryPurple,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTopToolsGrid() {
    final sourceTools = _searchQuery.isEmpty ? _randomTopTools : _allTools;
    final filteredTools = sourceTools.where((tool) {
      final title = tool['title'].toString().toLowerCase().replaceAll('\n', ' ');
      final subtitle = tool['subtitle'].toString().toLowerCase();
      return title.contains(_searchQuery) || subtitle.contains(_searchQuery);
    }).toList();

    if (filteredTools.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No tools found for "$_searchQuery"',
            style: AppTextStyles.bodyText.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 36) / 4;
        
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: filteredTools.map((tool) {
            return SizedBox(
              width: itemWidth,
              height: 125,
              child: _buildToolCard(
                title: tool['title'] as String,
                subtitle: tool['subtitle'] as String,
                backgroundColor: tool['color'] as Color,
                icon: tool['icon'] as IconData,
                iconColor: tool['iconColor'] as Color,
                onTap: () {
                  ref.read(historyProvider.notifier).addToolToHistory(
                    tool['title'] as String,
                    tool['subtitle'] as String,
                    tool['icon'] as IconData,
                    tool['color'] as Color,
                    tool['iconColor'] as Color,
                  );

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
                    _showComingSoon();
                  }
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildToolCard({
    required String title,
    required String subtitle,
    required Color backgroundColor,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? _showComingSoon,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
          boxShadow: [
            BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(3, 3), blurRadius: 0),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.toolCardTitle.copyWith(
                fontSize: 11,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                fontSize: 9.5,
                color: iconColor.withValues(alpha: 0.9),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    final actions = [
      {'title': 'Search Tool', 'subtitle': 'Find any tool', 'icon': Icons.search_rounded, 'iconColor': AppColors.primaryPurple, 'bgColor': const Color(0xFFEBE6FF), 'tab': 1},
      {'title': 'Favorites', 'subtitle': 'Your saved tools', 'icon': Icons.star_rounded, 'iconColor': AppColors.primaryYellow, 'bgColor': const Color(0xFFFFF6D9), 'tab': 2},
      {'title': 'Recently Used', 'subtitle': 'Continue where you left', 'icon': Icons.access_time_rounded, 'iconColor': AppColors.primaryBlue, 'bgColor': const Color(0xFFD9EDFF), 'tab': 3},
      {'title': 'My Collections', 'subtitle': 'Your tool collections', 'icon': Icons.collections_bookmark_outlined, 'iconColor': AppColors.primaryGreen, 'bgColor': const Color(0xFFD9FFEB), 'tab': 1},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 2.1,
        ),
        itemCount: actions.length,
        itemBuilder: (context, i) {
          final a = actions[i];
          return GestureDetector(
            onTap: () {
              final targetTab = a['tab'] as int;
              _navigateToTab(targetTab);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: a['bgColor'] as Color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
                boxShadow: [
                  BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(3, 3), blurRadius: 0),
                ],
              ),
              child: Row(
                children: [
                  Icon(a['icon'] as IconData, size: 24, color: a['iconColor'] as Color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          a['title'] as String,
                          style: AppTextStyles.toolCardTitle.copyWith(
                            fontSize: 12,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          a['subtitle'] as String,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 9,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentlyUsed() {
    final recent = ref.watch(historyProvider);

    if (recent.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
          ),
          child: Center(
            child: Text(
              'No recently used tools.\nExplore the grid above!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(recent.length > 3 ? 3 : recent.length, (i) {
          final item = recent[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GestureDetector(
              onTap: () {
                final t = item.title;
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
                  _showComingSoon();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
                  boxShadow: [
                    BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(4, 4), blurRadius: 0),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: item.bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                      ),
                      child: Icon(item.icon, size: 24, color: item.iconColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: AppTextStyles.toolCardTitle.copyWith(fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 11, 
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(Icons.star_border_rounded, size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                        const SizedBox(height: 8),
                        Text(
                          formatTimeAgo(item.timestamp),
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10, 
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Expanded(child: _buildNavItem(Icons.home_rounded, 'Home', 0)),
            Expanded(child: _buildNavItem(Icons.grid_view_rounded, 'Tools', 1)),
            Expanded(child: _buildNavItem(Icons.star_border_rounded, 'Favorites', 2)),
            Expanded(child: _buildNavItem(Icons.history_rounded, 'History', 3)),
            Expanded(child: _buildNavItem(Icons.person_outline_rounded, 'Profile', 4)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        _navigateToTab(index);
      },
      behavior: HitTestBehavior.opaque,
      child: isSelected
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
                boxShadow: [
                  BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2), blurRadius: 0),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.surface, size: 22),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: AppTextStyles.bottomNavigation.copyWith(
                        color: Theme.of(context).colorScheme.surface,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), size: 22),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: AppTextStyles.bottomNavigation.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
