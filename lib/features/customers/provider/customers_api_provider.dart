import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/customers_repository.dart';
import '../model/customer_list_item.dart';

/// State for the API-backed Customers list: the loaded pages plus paginator info.
class CustomersApiState {
  final List<CustomerListItem> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;

  const CustomersApiState({
    this.items = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.error,
  });

  bool get hasMore => currentPage < lastPage;

  CustomersApiState copyWith({
    List<CustomerListItem>? items,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
  }) {
    return CustomersApiState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Loads `GET /customers` page by page: replaces on page 1, appends on later
/// pages. A non-empty [_search] is sent to the server as `?search=`.
class CustomersApi extends Notifier<CustomersApiState> {
  String _search = '';
  Timer? _debounce;

  @override
  CustomersApiState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(() => _load(1));
    return const CustomersApiState(isLoading: true);
  }

  Future<void> _load(int page) async {
    final result = await ref
        .read(customersRepositoryProvider)
        .getCustomers(page: page, search: _search);
    result.when(
      success: (data) {
        state = state.copyWith(
          items: page == 1 ? data.items : [...state.items, ...data.items],
          currentPage: data.currentPage,
          lastPage: data.lastPage,
          total: data.total,
          isLoading: false,
          isLoadingMore: false,
          clearError: true,
        );
      },
      failure: (e) {
        state = state.copyWith(
            isLoading: false, isLoadingMore: false, error: e);
      },
    );
  }

  /// Fetches and appends the next page. No-op while loading or on the last page.
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    await _load(state.currentPage + 1);
  }

  /// Reloads from page 1.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _load(1);
  }

  /// Creates a customer via `POST /customers`, then reloads the list so the new
  /// row appears. Returns null on success, or the error message on failure.
  Future<String?> createCustomer({
    required String name,
    String? email,
    String? phone,
    String? address,
  }) async {
    final result = await ref.read(customersRepositoryProvider).createCustomer(
          name: name,
          email: email,
          phone: phone,
          address: address,
        );
    final error = result.errorOrNull;
    if (error != null) return error.message;
    await refresh();
    return null;
  }

  /// Updates a customer via `PUT /customers/{id}`, then reloads the list so the
  /// row reflects the edit. Returns null on success, or the error message.
  Future<String?> updateCustomer(
    String id, {
    required String name,
    String? email,
    String? phone,
    String? address,
  }) async {
    final result = await ref.read(customersRepositoryProvider).updateCustomer(
          id,
          name: name,
          email: email,
          phone: phone,
          address: address,
        );
    final error = result.errorOrNull;
    if (error != null) return error.message;
    await refresh();
    return null;
  }

  /// Debounced server-side search. Updates `?search=` and reloads from page 1.
  void setSearch(String query) {
    final next = query.trim();
    if (next == _search) return;
    _search = next;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      state = state.copyWith(isLoading: true, clearError: true);
      _load(1);
    });
  }
}

final customersApiProvider =
    NotifierProvider<CustomersApi, CustomersApiState>(CustomersApi.new);
