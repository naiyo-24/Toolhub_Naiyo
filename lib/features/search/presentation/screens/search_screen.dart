import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';
import 'package:tool_hub/core/utils/dialog_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:tool_hub/core/api/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tool_hub/core/data/tools_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/features/auth/presentation/providers/auth_provider.dart';
import 'package:tool_hub/features/tools/finance/presentation/screens/finance_tools_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;
  List<String> _searchHistory = [];

  final List<Map<String, dynamic>> _allCategories = [
    {'title': 'Daily Utility', 'description': '8+ Tools', 'color': const Color(0xFFE4D9FF), 'icon': Icons.grid_view_rounded, 'iconColor': AppColors.primaryPurple, 'url': '/daily-utility'},
    {'title': 'Internet Tools', 'description': 'Network Utilities', 'color': const Color(0xFFD9EDFF), 'icon': Icons.public_rounded, 'iconColor': AppColors.primaryBlue, 'url': '/internet-tools'},
    {'title': 'File Tools', 'description': 'File Utilities', 'color': const Color(0xFFD9FFEB), 'icon': Icons.folder_rounded, 'iconColor': AppColors.primaryGreen, 'url': '/file-sharing'},
    {'title': 'AI Tools', 'description': 'AI Powered', 'color': const Color(0xFFFFE8D9), 'icon': Icons.smart_toy_outlined, 'iconColor': const Color(0xFFFF8C00), 'url': '/ai-tools'},
    {'title': 'Student Toolkit', 'description': '15+ Tools', 'color': const Color(0xFFFFD9EA), 'icon': Icons.school_outlined, 'iconColor': AppColors.primaryPink, 'url': '/student-toolkit'},
    {'title': 'DocuForge', 'description': 'PDF Tools', 'color': const Color(0xFFD9F9FF), 'icon': Icons.picture_as_pdf_outlined, 'iconColor': const Color(0xFF00A2C7), 'url': '/docu-forge'},
    {'title': 'Finance Tools', 'description': 'Money Manager', 'color': const Color(0xFFFFF6D9), 'icon': Icons.account_balance_rounded, 'iconColor': AppColors.primaryYellow, 'url': '/finance-tools'},
    {'title': 'Business Toolkit', 'description': '15+ Tools', 'color': const Color(0xFFE9D9FF), 'icon': Icons.business_center_outlined, 'iconColor': const Color(0xFF8B00FF), 'url': '/business-toolkit'},
    {'title': 'Social Tools', 'description': 'Social Media', 'color': const Color(0xFFFFD9D9), 'icon': Icons.connect_without_contact_rounded, 'iconColor': AppColors.primaryRed, 'url': '/social-tools'},
    {'title': 'Health & Lifestyle', 'description': 'Wellness', 'color': const Color(0xFFD9FFED), 'icon': Icons.favorite_border_rounded, 'iconColor': const Color(0xFF00C853), 'url': '/health-lifestyle'},
    {'title': 'Productivity', 'description': 'Get things done', 'color': const Color(0xFFFFEBD9), 'icon': Icons.access_time_filled_rounded, 'iconColor': const Color(0xFFFF9800), 'url': '/productivity'},
    {'title': 'Travel Tools', 'description': 'Explore the world', 'color': const Color(0xFFD9F2FF), 'icon': Icons.flight_takeoff_rounded, 'iconColor': const Color(0xFF00B0FF), 'url': '/travel-tools'},
    {'title': 'Form Builder', 'description': 'Custom forms', 'color': const Color(0xFFF2D9FF), 'icon': Icons.dynamic_form_rounded, 'iconColor': const Color(0xFFD500F9), 'url': '/form-builder'},
  ];

  late final List<Map<String, dynamic>> _defaultSuggestions;

  @override
  void initState() {
    super.initState();
    _defaultSuggestions = _allCategories.take(4).toList();
    _searchResults = _defaultSuggestions;
    
    _loadSearchHistory();

    // Auto focus the text field when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _saveSearchToHistory(String query) async {
    if (query.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('search_history') ?? [];
    
    // Remove if already exists to move it to the top
    history.remove(query);
    history.insert(0, query);
    
    // Keep only last 10
    if (history.length > 10) {
      history.removeLast();
    }
    
    await prefs.setStringList('search_history', history);
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    setState(() {
      _searchHistory = [];
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = _defaultSuggestions;
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });

    final lowerQuery = query.toLowerCase();
    
    // 1. Search local categories and individual tools
    final List<Map<String, dynamic>> localCategoryResults = _allCategories.where((category) {
      final title = category['title'].toString().toLowerCase();
      final desc = category['description'].toString().toLowerCase();
      return title.contains(lowerQuery) || desc.contains(lowerQuery);
    }).toList();

    final List<Map<String, dynamic>> localToolResults = ToolsData.allTools.where((tool) {
      final title = tool['title'].toString().toLowerCase();
      final desc = tool['description'].toString().toLowerCase();
      final cat = tool['category'].toString().toLowerCase();
      return title.contains(lowerQuery) || desc.contains(lowerQuery) || cat.contains(lowerQuery);
    }).toList();

    final List<Map<String, dynamic>> allLocalResults = [...localCategoryResults, ...localToolResults];

    try {
      // 2. Search backend tools
      final url = Uri.parse('${ApiConfig.baseUrl}/tools/search?q=${Uri.encodeComponent(query)}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final backendResults = data.map((item) => {
          'title': item['name'],
          'description': item['description'],
          'url': item['url'],
          'icon': Icons.build_circle_outlined,
          'color': AppColors.primaryPurple,
          'iconColor': AppColors.primaryPurple,
        }).toList();

        setState(() {
          _searchResults = [...allLocalResults, ...backendResults];
          _isLoading = false;
        });
      } else {
        setState(() {
          _searchResults = allLocalResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _searchResults = allLocalResults;
        _isLoading = false;
      });
      // Optionally show a non-intrusive snackbar here, but if the backend is down 
      // we still want to show local categories without annoying the user too much.
    }
  }

  void _navigateToTool(String? url, String? title, String? category) {
    if (_searchController.text.isNotEmpty) {
      _saveSearchToHistory(_searchController.text);
    }
    
    if (url != null && url.isNotEmpty) {
      // Authentication check for Premium Tools
      final isPremiumCategory = category == 'Business Tool' || category == 'Form Builder';
      final isPremiumUrl = url == '/business-toolkit' || url == '/form-builder';
      
      if (isPremiumCategory || isPremiumUrl) {
        final isLoggedIn = ref.read(authProvider);
        if (!isLoggedIn) {
          SnackbarUtils.showNeoSnackBar(context, message: 'Please login to access Premium Tools');
          context.push('/business-login');
          return;
        }
      }

      if (url == '/ai-tools') {
        DialogUtils.showAIBottomSheet(context);
        return;
      }
      
      if (url.startsWith('/tools/')) {
        // Check if it's a dynamic finance tool first
        final endpoint = url.replaceFirst('/tools', '');
        final financeTool = FinanceToolsScreen.tools.where((t) => t['endpoint'] == endpoint).firstOrNull;
        
        if (financeTool != null) {
          if (financeTool['isExpenseTracker'] == true) {
            context.push('/finance-tools/expense-tracker', extra: financeTool);
          } else {
            context.push('/finance-tools/calculator', extra: financeTool);
          }
          return;
        }

        DialogUtils.showComingSoonBottomSheet(context, title: title ?? 'Coming Soon');
        return;
      }
      
      try {
        context.push(url);
      } catch (e) {
        DialogUtils.showComingSoonBottomSheet(context, title: title ?? 'Coming Soon');
      }
    } else {
      SnackbarUtils.showNeoSnackBar(context, message: 'Tool link not available.');
    }
  }

  void _onHistoryTap(String query) {
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(TextPosition(offset: query.length));
    _onSearchChanged(query);
  }

  @override
  Widget build(BuildContext context) {
    final bool isShowingDefaults = _searchController.text.isEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(context),
            const SizedBox(height: 24),
            
            if (isShowingDefaults && _searchHistory.isNotEmpty)
              _buildSearchHistory(),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                isShowingDefaults ? 'Suggestions' : 'Search Results',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
                : _searchResults.isEmpty 
                  ? Center(
                      child: Text('No tools found for "${_searchController.text}"', 
                        style: AppTextStyles.bodyText.copyWith(color: Colors.black54)
                      )
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        return _buildSuggestionItem(item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
              ),
              GestureDetector(
                onTap: _clearHistory,
                child: Text(
                  'Clear',
                  style: AppTextStyles.buttonText.copyWith(color: AppColors.primaryRed, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _searchHistory.map((query) {
              return GestureDetector(
                onTap: () => _onHistoryTap(query),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2), blurRadius: 0),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Text(
                        query,
                        style: AppTextStyles.bodyText.copyWith(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
                boxShadow: [
                  BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2), blurRadius: 0),
                ],
              ),
              child: Icon(Icons.arrow_back_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: NeoCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              borderRadius: 12,
              borderWidth: 2,
              shadowOffset: const Offset(2, 2),
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: AppTextStyles.bodyText.copyWith(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search tools...',
                  hintStyle: AppTextStyles.bodyText.copyWith(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  border: InputBorder.none,
                  icon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), size: 22),
                  suffixIcon: _searchController.text.isNotEmpty 
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        ) 
                      : null,
                ),
                onChanged: _onSearchChanged,
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    _saveSearchToHistory(val.trim());
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _navigateToTool(item['url'], item['title'], item['category']),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (item['color'] as Color? ?? AppColors.primaryPurple).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item['icon'] as IconData? ?? Icons.build_circle_outlined, color: item['color'] as Color? ?? AppColors.primaryPurple, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String,
                    style: AppTextStyles.toolCardTitle.copyWith(fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  if (item['description'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item['description'] as String,
                      style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]
                ],
              ),
            ),
            Icon(Icons.call_made_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), size: 16),
          ],
        ),
      ),
    );
  }
}
