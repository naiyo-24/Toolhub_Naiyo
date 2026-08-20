import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/loandesk_theme.dart';
import '../../widgets/neo_card.dart';
import '../../widgets/neo_button.dart';
import '../../providers/customer_provider.dart';
import '../../../domain/entities/customer.dart';

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
    final customersState = ref.watch(customerProvider);
    final notifier = ref.read(customerProvider.notifier);
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
              child: customersState.when(
                loading: () => const Center(child: CircularProgressIndicator(color: LoanDeskTheme.primaryBlack)),
                error: (error, _) => Center(child: Text('Error: $error')),
                data: (_) {
                  if (customers.isEmpty) {
                    return const Center(
                      child: Text('No customers found', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                    );
                  }
                  return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: customers.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return GestureDetector(
                    onTap: () => _showCustomerDetails(context, customer),
                    child: NeoCard(
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
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'customer_list_fab',
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

  void _showCustomerDetails(BuildContext context, Customer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: LoanDeskTheme.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, controller) {
              return CustomScrollView(
                controller: controller,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                              width: 50,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: LoanDeskTheme.primaryYellow,
                            child: Text(
                              customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: LoanDeskTheme.primaryBlack,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            customer.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: LoanDeskTheme.primaryBlack,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: LoanDeskTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: LoanDeskTheme.primaryBlue, width: 2),
                            ),
                            child: Text(
                              'ID: ${customer.id}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: LoanDeskTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: LoanDeskTheme.primaryBlack,
                          ),
                        ),
                        const SizedBox(height: 16),
                        NeoCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildDetailRow(Icons.phone, 'Phone Number', customer.phoneNumber),
                              const Divider(color: Colors.black12, height: 24, thickness: 1),
                              _buildDetailRow(Icons.email, 'Email Address', customer.email),
                              const Divider(color: Colors.black12, height: 24, thickness: 1),
                              _buildDetailRow(Icons.credit_card, 'PAN Number', customer.panNumber),
                              if (customer.dob != null) ...[
                                const Divider(color: Colors.black12, height: 24, thickness: 1),
                                _buildDetailRow(Icons.cake, 'Date of Birth', "${customer.dob!.day}/${customer.dob!.month}/${customer.dob!.year}"),
                              ],
                              if (customer.address.isNotEmpty) ...[
                                const Divider(color: Colors.black12, height: 24, thickness: 1),
                                _buildDetailRow(Icons.location_on, 'Address', customer.address),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Business Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: LoanDeskTheme.primaryBlack,
                          ),
                        ),
                        const SizedBox(height: 16),
                        NeoCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              if (customer.occupation != null && customer.occupation!.isNotEmpty) ...[
                                _buildDetailRow(Icons.work, 'Occupation', customer.occupation!),
                                const Divider(color: Colors.black12, height: 24, thickness: 1),
                              ],
                              if (customer.businessName != null && customer.businessName!.isNotEmpty) ...[
                                _buildDetailRow(Icons.business, 'Business Name', customer.businessName!),
                                const Divider(color: Colors.black12, height: 24, thickness: 1),
                              ],
                              if (customer.businessType != null && customer.businessType!.isNotEmpty) ...[
                                _buildDetailRow(Icons.category, 'Business Type', customer.businessType!),
                                const Divider(color: Colors.black12, height: 24, thickness: 1),
                              ],
                              if (customer.udyamNumber != null && customer.udyamNumber!.isNotEmpty) ...[
                                _buildDetailRow(Icons.verified_user, 'Udyam Number', customer.udyamNumber!),
                                const Divider(color: Colors.black12, height: 24, thickness: 1),
                              ],
                              if (customer.gstin != null && customer.gstin!.isNotEmpty) ...[
                                _buildDetailRow(Icons.receipt, 'GSTIN', customer.gstin!),
                              ] else ...[
                                _buildDetailRow(Icons.receipt, 'GSTIN', 'N/A'),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        NeoButton(
                          text: 'Close Details',
                          onPressed: () => Navigator.pop(context),
                          color: LoanDeskTheme.primaryWhite,
                        ),
                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: LoanDeskTheme.primaryYellow.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: LoanDeskTheme.primaryBlack),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? 'N/A' : value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: LoanDeskTheme.primaryBlack,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
