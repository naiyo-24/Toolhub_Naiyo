import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/features/loandesk/data/repositories/customer_repository.dart';
import '../../domain/entities/customer.dart';

final customerProvider = StateNotifierProvider<CustomerNotifier, AsyncValue<List<Customer>>>((ref) {
  final customerRepository = ref.watch(customerRepositoryProvider);
  return CustomerNotifier(customerRepository);
});

class CustomerNotifier extends StateNotifier<AsyncValue<List<Customer>>> {
  final CustomerRepository _customerRepository;

  CustomerNotifier(this._customerRepository) : super(const AsyncValue.loading()) {
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    state = const AsyncValue.loading();
    try {
      final customers = await _customerRepository.getCustomers();
      state = AsyncValue.data(customers);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<Customer> addCustomer(Map<String, dynamic> customerData) async {
    try {
      final newCustomer = await _customerRepository.createCustomer(customerData);
      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, newCustomer]);
      } else {
        state = AsyncValue.data([newCustomer]);
      }
      return newCustomer;
    } catch (e, stackTrace) {
      // Handle error accordingly, maybe update a separate error state provider
      // For now, keep the state as is and just throw
      throw e;
    }
  }

  List<Customer> searchCustomers(String query) {
    if (!state.hasValue || query.isEmpty) return state.valueOrNull ?? [];
    
    final lowerQuery = query.toLowerCase();
    return state.value!.where((c) {
      return c.name.toLowerCase().contains(lowerQuery) || 
             c.panNumber.toLowerCase().contains(lowerQuery) ||
             c.phoneNumber.contains(query);
    }).toList();
  }
}
