import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/customer_model.dart';

/// Master list of customers.
class CustomersNotifier extends Notifier<List<CustomerModel>> {
  @override
  List<CustomerModel> build() => CustomerModel.sampleCustomers();

  /// Adds a newly created customer to the top of the list.
  void add(CustomerModel customer) => state = [customer, ...state];

  void delete(String id) =>
      state = state.where((c) => c.id != id).toList();
}

final customersProvider =
    NotifierProvider<CustomersNotifier, List<CustomerModel>>(
        CustomersNotifier.new);

/// Free-text search applied to the customer list.
class CustomerSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setSearch(String q) => state = q;
}

final customerSearchProvider =
    NotifierProvider<CustomerSearchNotifier, String>(
        CustomerSearchNotifier.new);

/// Status selected in the "Create Customer" form. Kept in Riverpod so the
/// form's dropdown drives the UI without any local [setState].
class CustomerDraftStatusNotifier extends Notifier<CustomerStatus> {
  @override
  CustomerStatus build() => CustomerStatus.lead;

  void set(CustomerStatus s) => state = s;

  void reset() => state = CustomerStatus.lead;
}

final customerDraftStatusProvider =
    NotifierProvider<CustomerDraftStatusNotifier, CustomerStatus>(
        CustomerDraftStatusNotifier.new);

/// Selected section tab on the customer detail screen.
/// 0 = Contract, 1 = Won Products, 2 = History List.
class CustomerDetailTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final customerDetailTabProvider =
    NotifierProvider<CustomerDetailTabNotifier, int>(
        CustomerDetailTabNotifier.new);

/// Customers after applying the active search query.
final filteredCustomersProvider = Provider<List<CustomerModel>>((ref) {
  final customers = ref.watch(customersProvider);
  final q = ref.watch(customerSearchProvider).trim().toLowerCase();
  if (q.isEmpty) return customers;

  return customers.where((c) {
    return c.name.toLowerCase().contains(q) ||
        c.company.toLowerCase().contains(q) ||
        c.email.toLowerCase().contains(q) ||
        c.location.toLowerCase().contains(q);
  }).toList();
});
