import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/customer.dart';

final customerProvider = StateNotifierProvider<CustomerNotifier, List<Customer>>((ref) {
  return CustomerNotifier();
});

class CustomerNotifier extends StateNotifier<List<Customer>> {
  CustomerNotifier() : super([]) {
    // Seed with some mock data for the frontend
    state = [
      Customer(
        id: 'CUST-001',
        name: 'John Doe',
        panNumber: 'ABCDE1234F',
        phoneNumber: '9876543210',
        email: 'john@example.com',
        address: '123 Main St, Mumbai',
        createdDate: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Customer(
        id: 'CUST-002',
        name: 'Jane Smith',
        panNumber: 'FGHIJ5678K',
        phoneNumber: '9123456780',
        email: 'jane@example.com',
        address: '456 Linking Rd, Delhi',
        createdDate: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }

  void addCustomer(Customer customer) {
    state = [...state, customer];
  }

  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return state;
    
    final lowerQuery = query.toLowerCase();
    return state.where((c) {
      return c.name.toLowerCase().contains(lowerQuery) || 
             c.panNumber.toLowerCase().contains(lowerQuery) ||
             c.phoneNumber.contains(query);
    }).toList();
  }
}
