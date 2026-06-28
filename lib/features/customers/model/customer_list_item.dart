import 'package:flutter/widgets.dart';

import 'customer_model.dart';

/// A single customer from `GET /customers` (paginated). Maps the raw backend
/// row — most address fields are nullable — and exposes a few display helpers
/// used by the list card.
class CustomerListItem {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? country;
  final int? createdBy;
  final DateTime? createdAt;
  final int contactsCount;

  const CustomerListItem({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.country,
    this.createdBy,
    this.createdAt,
    this.contactsCount = 0,
  });

  /// First letters of the name, used for the avatar badge.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  String get displayEmail => (email?.trim().isNotEmpty ?? false) ? email! : '—';
  String get displayPhone => (phone?.trim().isNotEmpty ?? false) ? phone! : '—';

  /// Single-line location built from city / state / country, falling back to
  /// the street address, then a placeholder.
  String get location {
    final parts = [city, state, country]
        .where((p) => (p?.trim().isNotEmpty ?? false))
        .map((p) => p!.trim())
        .toList();
    if (parts.isNotEmpty) return parts.join(', ');
    final addr = address?.trim() ?? '';
    return addr.isNotEmpty ? addr : 'No location';
  }

  factory CustomerListItem.fromJson(Map<String, dynamic> json) {
    return CustomerListItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      country: json['country'] as String?,
      createdBy: (json['created_by'] as num?)?.toInt(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      contactsCount: (json['contacts_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Adapts this API row to the richer [CustomerModel] expected by the detail
  /// screen. Fields the list endpoint does not provide are left at sensible
  /// defaults (no contract / products / history).
  CustomerModel toCustomerModel() {
    return CustomerModel(
      id: id.toString(),
      name: name,
      company: (country?.trim().isNotEmpty ?? false) ? country!.trim() : '',
      email: displayEmail,
      phone: displayPhone,
      location: location,
      status: CustomerStatus.active,
      totalValue: 0,
      street: address ?? '',
      city: city ?? '',
      state: state ?? '',
      postalCode: pincode ?? '',
      country: country ?? '',
      createdAt: createdAt ?? DateTime.now(),
      createdBy: createdBy?.toString() ?? '',
    );
  }
}

/// One page of customers plus the Laravel paginator metadata.
class CustomersPage {
  final List<CustomerListItem> items;
  final int currentPage;
  final int lastPage;
  final int total;

  const CustomersPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}
