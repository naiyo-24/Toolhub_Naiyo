import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/loandesk_theme.dart';
import '../../widgets/neo_card.dart';
import '../../providers/customer_provider.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  final bool isTab;
  final VoidCallback? onBackToDashboard;

  const CustomerListScreen({
    super.key, 
    this.isTab = false,
    this.onBackToDashboard,
  });

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(customerProvider.notifier);
    final customers = notifier.searchCustomers(_searchQuery);

    return Scaffold(
      backgroundColor: LoanDeskTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: LoanDeskTheme.primaryWhite,
        elevation: 0,
        leading: widget.isTab && widget.onBackToDashboard == null 
            ? null 
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: LoanDeskTheme.primaryBlack),
                onPressed: () {
                  if (widget.isTab && widget.onBackToDashboard != null) {
                    widget.onBackToDashboard!();
                  } else {
                    context.pop();
                  }
                },
              ),
        title: const Text(
          'Customers',
          style: TextStyle(
            color: LoanDeskTheme.primaryBlack,
            fontWeight: FontWeight.w900,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: LoanDeskTheme.primaryBlack,
            height: LoanDeskTheme.borderWidth,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSearchBar(),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: customers.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return NeoCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              customer.id,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: LoanDeskTheme.primaryYellow,
                                borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
                                border: Border.all(color: LoanDeskTheme.primaryBlack, width: 2),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.credit_card, size: 14, color: Colors.black54),
                            const SizedBox(width: 4),
                            Text(
                              customer.panNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.phone, size: 14, color: Colors.black54),
                            const SizedBox(width: 4),
                            Text(
                              customer.phoneNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/loandesk/customers/add');
        },
        backgroundColor: LoanDeskTheme.primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
          side: const BorderSide(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
        ),
        child: const Icon(Icons.add, color: LoanDeskTheme.primaryWhite),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: LoanDeskTheme.primaryWhite,
        borderRadius: BorderRadius.circular(LoanDeskTheme.borderRadius),
        border: Border.all(
          color: LoanDeskTheme.primaryBlack,
          width: LoanDeskTheme.borderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: LoanDeskTheme.primaryBlack,
            offset: Offset(LoanDeskTheme.shadowOffset, LoanDeskTheme.shadowOffset),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: const InputDecoration(
          hintText: 'Search by Name, PAN, or Phone',
          prefixIcon: Icon(Icons.search, color: LoanDeskTheme.primaryBlack),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
