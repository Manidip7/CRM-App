import 'package:flutter/material.dart';

import '../../../core/utils/AppColors.dart';

/// Relationship status of a customer.
enum CustomerStatus { active, lead, inactive }

extension CustomerStatusName on CustomerStatus {
  String get label {
    switch (this) {
      case CustomerStatus.active:
        return 'Active';
      case CustomerStatus.lead:
        return 'Lead';
      case CustomerStatus.inactive:
        return 'Inactive';
    }
  }

  Color get color {
    switch (this) {
      case CustomerStatus.active:
        return AppColors.green;
      case CustomerStatus.lead:
        return AppColors.primary;
      case CustomerStatus.inactive:
        return AppColors.textSecondary;
    }
  }
}

/// A contact person under a customer (from the `contacts` array on
/// `GET /customers/{id}`).
class CustomerContact {
  final String name;
  final String email;
  final String phone;
  final String designation;
  final bool isPrimary;

  const CustomerContact({
    required this.name,
    this.email = '',
    this.phone = '',
    this.designation = '',
    this.isPrimary = false,
  });

  /// First letters of the name, used for the avatar badge.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  factory CustomerContact.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => v == null ? '' : '$v'.trim();

    // Contacts may carry a split name (first/last) or a single `name` field.
    final composed = [str(json['first_name']), str(json['last_name'])]
        .where((s) => s.isNotEmpty)
        .join(' ')
        .trim();

    final primary = json['is_primary'] ?? json['primary'];

    return CustomerContact(
      name: composed.isNotEmpty ? composed : str(json['name']),
      email: str(json['email']),
      phone: str(json['phone'] ?? json['mobile'] ?? json['contact_number']),
      designation:
          str(json['designation'] ?? json['role'] ?? json['position']),
      isPrimary: primary is bool
          ? primary
          : (primary is num ? primary != 0 : str(primary) == '1'),
    );
  }
}

/// Contract attached to a customer.
class ContractInfo {
  final String number;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final double value;
  final bool active;

  const ContractInfo({
    required this.number,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.value,
    this.active = true,
  });

  factory ContractInfo.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final status = '${json['status'] ?? ''}'.toLowerCase();
    return ContractInfo(
      number: '${json['number'] ?? json['contract_number'] ?? ''}',
      title: '${json['title'] ?? json['name'] ?? ''}',
      startDate: DateTime.tryParse('${json['start_date']}') ?? now,
      endDate: DateTime.tryParse('${json['end_date']}') ?? now,
      value: (json['value'] as num?)?.toDouble() ?? 0,
      active: json['active'] as bool? ??
          (status.isEmpty ? true : status == 'active'),
    );
  }
}

/// A product the customer has purchased (a "won" deal line).
class WonProduct {
  final String name;
  final int quantity;
  final double amount;

  const WonProduct({
    required this.name,
    required this.quantity,
    required this.amount,
  });

  factory WonProduct.fromJson(Map<String, dynamic> json) {
    return WonProduct(
      name: '${json['name'] ?? json['product_name'] ?? ''}',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ??
          (json['value'] as num?)?.toDouble() ??
          0,
    );
  }
}

/// One entry in the customer activity history.
class HistoryEntry {
  final DateTime date;
  final String title;
  final String description;
  final String by;

  const HistoryEntry({
    required this.date,
    required this.title,
    required this.description,
    required this.by,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      date: DateTime.tryParse('${json['date'] ?? json['created_at']}') ??
          DateTime.now(),
      title: '${json['title'] ?? json['action'] ?? ''}',
      description: '${json['description'] ?? json['note'] ?? ''}',
      by: '${json['by'] ?? json['created_by_name'] ?? json['user'] ?? ''}',
    );
  }
}

class CustomerModel {
  final String id;
  final String name;
  final String company;
  final String email;
  final String phone;
  final String location;
  final CustomerStatus status;
  final double totalValue;

  // Address details
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  // Related records
  final ContractInfo? contract;
  final List<CustomerContact> contacts;
  final List<WonProduct> wonProducts;
  final List<HistoryEntry> history;

  // Audit
  final DateTime createdAt;
  final String createdBy;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.company,
    required this.email,
    required this.phone,
    required this.location,
    required this.status,
    required this.totalValue,
    required this.createdAt,
    required this.createdBy,
    this.street = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.country = '',
    this.contract,
    this.contacts = const [],
    this.wonProducts = const [],
    this.history = const [],
  });

  /// Builds a full [CustomerModel] from the `GET /customers/{id}` detail
  /// payload (the object under `data`). The core contact/address fields match
  /// the list row; the nested contract / products / history sections are parsed
  /// defensively so a shape the backend doesn't send simply comes back empty.
  factory CustomerModel.fromDetailJson(Map<String, dynamic> json) {
    String str(dynamic v) => v == null ? '' : '$v'.trim();

    final city = str(json['city']);
    final state = str(json['state']);
    final country = str(json['country']);
    final locationParts = [city, state, country].where((p) => p.isNotEmpty);

    final contractJson = (json['contract'] as Map?)?.cast<String, dynamic>();
    final contactsJson = json['contacts'] as List? ?? const [];
    final productsJson =
        (json['won_products'] ?? json['products']) as List? ?? const [];
    final historyJson =
        (json['history'] ?? json['activities']) as List? ?? const [];

    return CustomerModel(
      id: str(json['id']),
      name: str(json['name']),
      company: str(json['company']),
      email: str(json['email']).isEmpty ? '—' : str(json['email']),
      phone: str(json['phone']).isEmpty ? '—' : str(json['phone']),
      location:
          locationParts.isEmpty ? 'No location' : locationParts.join(', '),
      status: _statusFromString(str(json['status'])),
      totalValue: (json['total_value'] as num?)?.toDouble() ?? 0,
      street: str(json['address']),
      city: city,
      state: state,
      postalCode: str(json['pincode']),
      country: country,
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
      createdBy: str(json['created_by_name'] ?? json['created_by']),
      contract:
          contractJson == null ? null : ContractInfo.fromJson(contractJson),
      contacts: contactsJson
          .whereType<Map>()
          .map((e) => CustomerContact.fromJson(e.cast<String, dynamic>()))
          .toList(),
      wonProducts: productsJson
          .whereType<Map>()
          .map((e) => WonProduct.fromJson(e.cast<String, dynamic>()))
          .toList(),
      history: historyJson
          .whereType<Map>()
          .map((e) => HistoryEntry.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  static CustomerStatus _statusFromString(String value) {
    switch (value.toLowerCase().trim()) {
      case 'active':
        return CustomerStatus.active;
      case 'inactive':
        return CustomerStatus.inactive;
      case 'lead':
        return CustomerStatus.lead;
      default:
        return CustomerStatus.active;
    }
  }

  /// First letters of the name, used for the avatar badge.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  /// "$12.5k" style label for the total deal value.
  String get valueLabel => _money(totalValue);

  /// Single-line formatted address built from the address parts.
  String get fullAddress {
    final parts = [
      street,
      city,
      state,
      postalCode,
      country,
    ].where((p) => p.trim().isNotEmpty).toList();
    return parts.isEmpty ? 'No address on file' : parts.join(', ');
  }

  static String _money(double v) {
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}k';
    return '\$${v.toStringAsFixed(0)}';
  }

  static List<CustomerModel> sampleCustomers() {
    return [
      CustomerModel(
        id: '1',
        name: 'Rahul Sharma',
        company: 'Acme Corp',
        email: 'rahul@acme.com',
        phone: '+91 98765 43210',
        location: 'Mumbai',
        status: CustomerStatus.active,
        totalValue: 125000,
        street: '402, Lotus Business Park',
        city: 'Mumbai',
        state: 'Maharashtra',
        postalCode: '400063',
        country: 'India',
        createdAt: DateTime(2024, 3, 12),
        createdBy: 'Admin Owner',
        contract: ContractInfo(
          number: 'CON-2024-001',
          title: 'Annual SaaS Subscription',
          startDate: DateTime(2024, 4, 1),
          endDate: DateTime(2025, 3, 31),
          value: 125000,
          active: true,
        ),
        wonProducts: const [
          WonProduct(name: 'CRM Pro License', quantity: 25, amount: 75000),
          WonProduct(name: 'Analytics Add-on', quantity: 1, amount: 30000),
          WonProduct(name: 'Onboarding Package', quantity: 1, amount: 20000),
        ],
        history: [
          HistoryEntry(
            date: DateTime(2024, 4, 1),
            title: 'Contract signed',
            description: 'Annual subscription activated.',
            by: 'Admin Owner',
          ),
          HistoryEntry(
            date: DateTime(2024, 6, 15),
            title: 'Upsell — Analytics Add-on',
            description: 'Added analytics module to plan.',
            by: 'Priya Nair',
          ),
          HistoryEntry(
            date: DateTime(2024, 9, 2),
            title: 'Quarterly review',
            description: 'Reviewed usage and renewal plan.',
            by: 'Admin Owner',
          ),
        ],
      ),
      CustomerModel(
        id: '2',
        name: 'Priya Nair',
        company: 'TechStart',
        email: 'priya@techstart.io',
        phone: '+91 90123 45678',
        location: 'Bengaluru',
        status: CustomerStatus.active,
        totalValue: 86000,
        street: '12, Indiranagar 100ft Road',
        city: 'Bengaluru',
        state: 'Karnataka',
        postalCode: '560038',
        country: 'India',
        createdAt: DateTime(2024, 1, 20),
        createdBy: 'Admin Owner',
        contract: ContractInfo(
          number: 'CON-2024-014',
          title: 'Growth Plan',
          startDate: DateTime(2024, 2, 1),
          endDate: DateTime(2025, 1, 31),
          value: 86000,
          active: true,
        ),
        wonProducts: const [
          WonProduct(name: 'CRM Growth License', quantity: 15, amount: 60000),
          WonProduct(name: 'Email Automation', quantity: 1, amount: 26000),
        ],
        history: [
          HistoryEntry(
            date: DateTime(2024, 2, 1),
            title: 'Contract signed',
            description: 'Growth plan activated.',
            by: 'Admin Owner',
          ),
          HistoryEntry(
            date: DateTime(2024, 7, 10),
            title: 'Support ticket resolved',
            description: 'Resolved integration issue.',
            by: 'Amit Verma',
          ),
        ],
      ),
      CustomerModel(
        id: '3',
        name: 'Amit Verma',
        company: 'GlobalNet',
        email: 'amit@globalnet.com',
        phone: '+91 99887 76655',
        location: 'Delhi',
        status: CustomerStatus.lead,
        totalValue: 42000,
        street: '88, Connaught Place',
        city: 'New Delhi',
        state: 'Delhi',
        postalCode: '110001',
        country: 'India',
        createdAt: DateTime(2024, 5, 5),
        createdBy: 'Priya Nair',
        wonProducts: const [
          WonProduct(name: 'CRM Starter License', quantity: 10, amount: 42000),
        ],
        history: [
          HistoryEntry(
            date: DateTime(2024, 5, 5),
            title: 'Lead created',
            description: 'Inbound enquiry from website.',
            by: 'Priya Nair',
          ),
        ],
      ),
      CustomerModel(
        id: '4',
        name: 'Sneha Iyer',
        company: 'Vertex Inc',
        email: 'sneha@vertex.com',
        phone: '+91 91234 56780',
        location: 'Pune',
        status: CustomerStatus.lead,
        totalValue: 23000,
        street: '7, Baner Road',
        city: 'Pune',
        state: 'Maharashtra',
        postalCode: '411045',
        country: 'India',
        createdAt: DateTime(2024, 8, 18),
        createdBy: 'Admin Owner',
        history: [
          HistoryEntry(
            date: DateTime(2024, 8, 18),
            title: 'Lead created',
            description: 'Referred by existing customer.',
            by: 'Admin Owner',
          ),
        ],
      ),
      CustomerModel(
        id: '5',
        name: 'Karan Mehta',
        company: 'BrightCo',
        email: 'karan@brightco.com',
        phone: '+91 98989 12345',
        location: 'Hyderabad',
        status: CustomerStatus.inactive,
        totalValue: 15000,
        street: '21, HITEC City',
        city: 'Hyderabad',
        state: 'Telangana',
        postalCode: '500081',
        country: 'India',
        createdAt: DateTime(2023, 11, 2),
        createdBy: 'Admin Owner',
        contract: ContractInfo(
          number: 'CON-2023-090',
          title: 'Starter Plan',
          startDate: DateTime(2023, 11, 15),
          endDate: DateTime(2024, 11, 14),
          value: 15000,
          active: false,
        ),
        wonProducts: const [
          WonProduct(name: 'CRM Starter License', quantity: 5, amount: 15000),
        ],
        history: [
          HistoryEntry(
            date: DateTime(2023, 11, 15),
            title: 'Contract signed',
            description: 'Starter plan activated.',
            by: 'Admin Owner',
          ),
          HistoryEntry(
            date: DateTime(2024, 11, 14),
            title: 'Contract expired',
            description: 'Plan not renewed.',
            by: 'System',
          ),
        ],
      ),
      CustomerModel(
        id: '6',
        name: 'Anjali Gupta',
        company: 'NovaSoft',
        email: 'anjali@novasoft.com',
        phone: '+91 90909 80808',
        location: 'Chennai',
        status: CustomerStatus.active,
        totalValue: 98000,
        street: '9, OMR Thoraipakkam',
        city: 'Chennai',
        state: 'Tamil Nadu',
        postalCode: '600097',
        country: 'India',
        createdAt: DateTime(2024, 2, 28),
        createdBy: 'Amit Verma',
        contract: ContractInfo(
          number: 'CON-2024-022',
          title: 'Enterprise Plan',
          startDate: DateTime(2024, 3, 1),
          endDate: DateTime(2025, 2, 28),
          value: 98000,
          active: true,
        ),
        wonProducts: const [
          WonProduct(
            name: 'CRM Enterprise License',
            quantity: 30,
            amount: 80000,
          ),
          WonProduct(name: 'Priority Support', quantity: 1, amount: 18000),
        ],
        history: [
          HistoryEntry(
            date: DateTime(2024, 3, 1),
            title: 'Contract signed',
            description: 'Enterprise plan activated.',
            by: 'Amit Verma',
          ),
        ],
      ),
    ];
  }
}
