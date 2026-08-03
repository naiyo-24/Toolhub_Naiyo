import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tool_hub/core/theme/app_colors.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/widgets/universal_tool_card.dart';


class FormBuilderScreen extends ConsumerStatefulWidget {
  const FormBuilderScreen({super.key});

  @override
  ConsumerState<FormBuilderScreen> createState() => _FormBuilderScreenState();
}

class _FormBuilderScreenState extends ConsumerState<FormBuilderScreen> with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  bool _showAllTools = false;
  
  bool _isSigningIn = false;
  String? _userPic;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  final List<Map<String, dynamic>> tools = [
      {'title': 'Custom Form', 'subtitle': 'Start from scratch', 'icon': Icons.add_box_rounded, 'color': AppColors.primaryYellow, 'actionText': 'Create'},
      {'title': 'Contact Form', 'subtitle': 'Create contact forms', 'icon': Icons.contact_mail_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Create'},
      {'title': 'Survey Form', 'subtitle': 'Build surveys', 'icon': Icons.poll_rounded, 'color': AppColors.primaryGreen, 'actionText': 'Create'},
      {'title': 'Feedback Form', 'subtitle': 'Collect feedback', 'icon': Icons.feedback_rounded, 'color': AppColors.primaryPink, 'actionText': 'Create'},
      {'title': 'Registration', 'subtitle': 'Event registration', 'icon': Icons.how_to_reg_rounded, 'color': AppColors.primaryRed, 'actionText': 'Create'},
      {'title': 'Job App', 'subtitle': 'Hiring forms', 'icon': Icons.work_rounded, 'color': AppColors.primaryPurple, 'actionText': 'Create'},
      {'title': 'Order Form', 'subtitle': 'Product orders', 'icon': Icons.shopping_cart_rounded, 'color': AppColors.primaryPink, 'actionText': 'Create'},
      {'title': 'Quiz Builder', 'subtitle': 'Create quizzes', 'icon': Icons.quiz_rounded, 'color': AppColors.primaryBlue, 'actionText': 'Create'},
      {'title': 'Poll Creator', 'subtitle': 'Quick voting', 'icon': Icons.how_to_vote_rounded, 'color': AppColors.primaryYellow, 'actionText': 'Create'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserPic();
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPic() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userPic = prefs.getString('user_pic');
    });
  }

  Future<void> _handleSignIn() async {
    setState(() => _isSigningIn = true);
    try {
      final success = await ref.read(authProvider.notifier).signInWithGoogle();
      if (success) {
        await _loadUserPic();
      }
    } catch (error) {
      if (kDebugMode) {
        print(error);
      }
    } finally {
      setState(() => _isSigningIn = false);
    }
  }

  Future<void> _handleSignOut() async {
    await ref.read(authProvider.notifier).signOut();
    setState(() {
      _userPic = null;
    });
  }

  void _openCreateForm(BuildContext context, String formType) {
    context.push('/create-form', extra: formType);
  }

  Widget _buildLoginWall() {
    return Expanded(
      child: Stack(
        children: [
          // Neo-brutalist grid background
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(),
            ),
          ),
          
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: NeoCard(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(8),
                borderRadius: 50,
                onTap: () => context.pop(),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 24),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: const NeoCard(
                    backgroundColor: AppColors.primaryPurple,
                    borderWidth: 4,
                    padding: EdgeInsets.all(32),
                    borderRadius: 100,
                    shadowOffset: Offset(8, 8),
                    child: Icon(
                      Icons.assignment_rounded,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                
                NeoCard(
                  backgroundColor: AppColors.primaryYellow,
                  borderWidth: 4,
                  padding: const EdgeInsets.all(32),
                  shadowOffset: const Offset(8, 8),
                  child: Column(
                    children: [
                      Text(
                        'FORM\nBUILDER',
                        style: AppTextStyles.heroTitle.copyWith(
                          color: Colors.black,
                          fontSize: 32,
                          height: 1.1,
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 4,
                        width: 60,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sign in to create, manage, and share powerful custom forms and surveys.',
                        style: AppTextStyles.bodyText.copyWith(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                
                // Neo-brutalist Button
                NeoCard(
                  backgroundColor: Colors.white,
                  borderWidth: 4,
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shadowOffset: const Offset(6, 6),
                  onTap: _isSigningIn ? null : _handleSignIn,
                  child: Center(
                    child: _isSigningIn 
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                              height: 24,
                              width: 24,
                            ),
                            const SizedBox(width: 16),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Continue with Google',
                                  style: AppTextStyles.toolCardTitle.copyWith(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(authProvider);

    var filteredTools = tools.where((tool) {
      final title = (tool['title'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query);
    }).toList();

    if (_searchQuery.isEmpty && !_showAllTools) {
      filteredTools = filteredTools.take(6).toList();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            if (isLoggedIn) _buildHeader(context, isLoggedIn),
            if (isLoggedIn) _buildSearchBar(),
            if (!isLoggedIn)
              _buildLoginWall()
            else
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
                          return _buildUtilityCard(context, tool);
                        },
                      ),
                      if (_searchQuery.isEmpty && tools.length > 6)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 40),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _showAllTools = !_showAllTools;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryYellow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black,
                                    offset: Offset(4, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                _showAllTools ? 'View Less' : 'View More',
                                style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
                              ),
                            ),
                          ),
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

  Widget _buildHeader(BuildContext context, bool isLoggedIn) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: NeoCard(
        backgroundColor: AppColors.primaryYellow,
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
                        'Form ',
                        style: AppTextStyles.heroTitle.copyWith(fontSize: 22, color: Colors.black),
                      ),
                      Text(
                        'Builder',
                        style: AppTextStyles.logoText.copyWith(fontSize: 22, color: Colors.black, fontWeight: FontWeight.normal, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  Text(
                    'CREATE CUSTOM FORMS',
                    style: AppTextStyles.caption.copyWith(fontSize: 9, letterSpacing: 2, color: Colors.black87),
                  ),
                ],
              ),
            ),
            if (!isLoggedIn)
              GestureDetector(
                onTap: () => context.push('/my-forms'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.list_alt_rounded, color: Colors.black, size: 18),
                      const SizedBox(width: 4),
                      Text('My Forms', style: AppTextStyles.caption.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )
            else
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') {
                    _handleSignOut();
                  } else if (value == 'my_forms') {
                    context.push('/my-forms');
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'my_forms',
                    child: Text('My Forms'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('Sign Out', style: TextStyle(color: Colors.red)),
                  ),
                ],
                child: CircleAvatar(
                  backgroundImage: (_userPic != null && _userPic!.isNotEmpty) ? NetworkImage(_userPic!) : null,
                  backgroundColor: Colors.white,
                  child: (_userPic == null || _userPic!.isEmpty) ? const Icon(Icons.person, color: Colors.black) : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search form tools...',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.onSurface),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }

  Widget _buildUtilityCard(BuildContext context, Map<String, dynamic> tool) {
    final cardColor = tool['color'] as Color;

    return UniversalToolCard(
      title: tool['title'] as String,
      subtitle: tool['subtitle'] as String?,
      color: cardColor,
      icon: tool['icon'] as IconData,
      actionText: tool['actionText'] as String,
      onTap: () => _openCreateForm(context, tool['title'] as String),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.03)
      ..strokeWidth = 2;

    const spacing = 30.0;
    
    // Draw horizontal lines
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
    
    // Draw vertical lines
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
