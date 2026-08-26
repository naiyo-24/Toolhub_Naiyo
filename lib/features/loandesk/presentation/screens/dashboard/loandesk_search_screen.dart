import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/loandesk_theme.dart';
import '../../widgets/neo_card.dart';
import '../../providers/search_provider.dart';

class LoanDeskSearchScreen extends ConsumerStatefulWidget {
  const LoanDeskSearchScreen({super.key});

  @override
  ConsumerState<LoanDeskSearchScreen> createState() => _LoanDeskSearchScreenState();
}

class _LoanDeskSearchScreenState extends ConsumerState<LoanDeskSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchProvider.notifier).search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: LoanDeskTheme.background,
      appBar: AppBar(
        backgroundColor: LoanDeskTheme.primaryWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: LoanDeskTheme.primaryBlack),
          onPressed: () {
            ref.read(searchProvider.notifier).clear();
            context.pop();
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Search Customer / Case ID / PAN',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: LoanDeskTheme.primaryBlack,
            height: LoanDeskTheme.borderWidth,
          ),
        ),
      ),
      body: searchState.when(
        data: (SearchResponse? data) {
          if (data == null) {
            return const Center(child: Text('Type to start searching...'));
          }

          final customers = data.customers;
          final cases = data.cases;

          if (customers.isEmpty && cases.isEmpty) {
            return const Center(child: Text('No results found.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (cases.isNotEmpty) ...[
                const Text('Cases', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                ...cases.map((c) => _buildCaseItem(c)).toList(),
                const SizedBox(height: 24),
              ],
              if (customers.isNotEmpty) ...[
                const Text('Customers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                ...customers.map((c) => _buildCustomerItem(c)).toList(),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: LoanDeskTheme.primaryBlack)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildCaseItem(dynamic c) {
    // Assuming backend returns dict with case_number, customer_id, loan_type, amount, status
    final id = c['case_number']?.toString() ?? '';
    final type = c['loan_type']?.toString() ?? '';
    final status = c['status']?.toString() ?? '';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () => context.push('/loandesk/cases/workspace/${c['id']}'),
        child: NeoCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(id, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: LoanDeskTheme.primaryYellow,
                      borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
                      border: Border.all(color: LoanDeskTheme.primaryBlack),
                    ),
                    child: Text(status, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Loan Type: $type', style: const TextStyle(color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerItem(dynamic c) {
    // Assuming backend returns dict with full_name, pan, mobile
    final name = c['full_name']?.toString() ?? c['name']?.toString() ?? 'Unknown';
    final pan = c['pan']?.toString() ?? 'N/A';
    final phone = c['mobile']?.toString() ?? c['phone']?.toString() ?? 'N/A';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Go to Customers tab to view full details.')),
          );
        },
        child: NeoCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 4),
              Text('PAN: $pan | Phone: $phone', style: const TextStyle(color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}
