import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import 'package:tool_hub/core/utils/snackbar_utils.dart';
import '../../data/finance_service.dart';

class ExpenseTrackerScreen extends StatefulWidget {
  final Map<String, dynamic> tool;
  const ExpenseTrackerScreen({super.key, required this.tool});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  final FinanceService _service = FinanceService();
  final TextEditingController _budgetController = TextEditingController();
  
  final List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = false;
  Map<String, dynamic>? _results;

  final List<String> _categories = [
    "Housing", "Food & Dining", "Transportation", "Utilities & Bills",
    "Entertainment", "Healthcare", "Shopping", "Travel", "Education", "Other"
  ];

  void _addExpense() {
    String selectedCategory = _categories[0];
    final amountController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Expense'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        setDialogState(() => selectedCategory = val!);
                      },
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Amount'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description (Optional)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text);
                    if (amount == null) {
                      SnackbarUtils.showNeoSnackBar(context, message: 'Invalid amount');
                      return;
                    }
                    setState(() {
                      _expenses.add({
                        'category': selectedCategory,
                        'amount': amount,
                        'description': descController.text,
                      });
                    });
                    context.pop();
                  },
                  child: const Text('Add'),
                )
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _calculate() async {
    final budget = double.tryParse(_budgetController.text);
    if (budget == null) {
      SnackbarUtils.showNeoSnackBar(context, message: 'Invalid monthly budget');
      return;
    }

    setState(() {
      _isLoading = true;
      _results = null;
    });

    try {
      final result = await _service.calculate('/expense-tracker', {
        'monthly_budget': budget,
        'expenses': _expenses,
      });
      setState(() {
        _results = result;
      });
    } catch (e) {
      if (mounted) SnackbarUtils.showNeoSnackBar(context, message: e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.tool['color'] as Color;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: color,
        title: Text(widget.tool['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const NeoCard(
              backgroundColor: Color(0xFFE0FBFC), // Light Blue tint
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.black),
                      SizedBox(width: 8),
                      Text('How to use', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    "1. Set your Monthly Budget.\n2. Tap 'Add Expense' to add individual expenses.\n3. Tap 'Analyze Expenses' to get a breakdown.",
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _budgetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monthly Budget',
                prefixIcon: Icon(Icons.account_balance_wallet, color: color),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Expenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _addExpense,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                  style: TextButton.styleFrom(foregroundColor: color),
                )
              ],
            ),
            const SizedBox(height: 16),
            if (_expenses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No expenses added yet.', style: TextStyle(color: Colors.grey))),
              )
            else
              ..._expenses.asMap().entries.map((e) {
                final index = e.key;
                final expense = e.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.2), child: Icon(Icons.receipt, color: color)),
                    title: Text('${expense['category']} - ₹${expense['amount']}'),
                    subtitle: Text(expense['description'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setState(() => _expenses.removeAt(index)),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? () {} : _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _isLoading ? 'Calculating...' : 'Track Expenses',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),

            if (_results != null) ...[
              const Text('Analysis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              NeoCard(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildResultRow('Total Budget', '₹${_results!['monthly_budget']}', color),
                    _buildResultRow('Total Expenses', '₹${_results!['total_spent']}', color),
                    _buildResultRow('Remaining Budget', '₹${_results!['remaining_balance']}', color),
                    _buildResultRow('Status', _results!['budget_status'], color),
                    if (_results!['highest_expense_category'] != null)
                      _buildResultRow('Highest Category', _results!['highest_expense_category'].toString(), color),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
