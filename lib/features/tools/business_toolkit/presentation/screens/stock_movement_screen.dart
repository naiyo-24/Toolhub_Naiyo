import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import '../providers/business_provider.dart';

class StockMovementScreen extends ConsumerStatefulWidget {
  final int productId;
  final String productName;

  const StockMovementScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  ConsumerState<StockMovementScreen> createState() => _StockMovementScreenState();
}

class _StockMovementScreenState extends ConsumerState<StockMovementScreen> {
  bool _isLoading = true;
  List<dynamic> _movements = [];

  @override
  void initState() {
    super.initState();
    _fetchMovements();
  }

  Future<void> _fetchMovements() async {
    try {
      final service = ref.read(businessServiceProvider);
      final history = await service.getStockMovements(widget.productId);
      if (mounted) {
        setState(() {
          _movements = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Movement Ledger', style: AppTextStyles.screenHeading),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'History for: ${widget.productName}',
                    style: AppTextStyles.sectionTitle,
                  ),
                ),
                Expanded(
                  child: _movements.isEmpty
                      ? Center(
                          child: Text(
                            'No stock movements found.',
                            style: AppTextStyles.bodyText.copyWith(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _movements.length,
                          itemBuilder: (context, index) {
                            final m = _movements[index];
                            final isPurchase = m['movement_type'] == 'PURCHASE';
                            final qty = m['quantity_change'];
                            
                            return NeoCard(
                              backgroundColor: isPurchase ? Colors.green.shade50 : Colors.red.shade50,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isPurchase ? Colors.green : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isPurchase ? Icons.add_shopping_cart : Icons.remove_shopping_cart,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m['reference_id'] ?? 'Unknown Reference',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        Text(
                                          m['date'] ?? '',
                                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${qty > 0 ? '+' : ''}$qty',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                      color: isPurchase ? Colors.green.shade800 : Colors.red.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
