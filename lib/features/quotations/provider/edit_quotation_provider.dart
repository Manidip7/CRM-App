import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/quotation_model.dart';

/// One editable line item in the edit form. [key] is a stable identity used for
/// widget keys so rows keep their text-field state across add / remove.
class EditItem {
  final int key;

  /// Catalog product (`GET /products`) chosen for this row, null until picked.
  final int? productId;

  final String name;

  /// HSN / SAC code for the item.
  final String hsn;

  final int quantity;
  final double price;

  const EditItem({
    required this.key,
    this.productId,
    this.name = '',
    this.hsn = '',
    this.quantity = 1,
    this.price = 0,
  });

  double get total => quantity * price;

  EditItem copyWith({
    int? productId,
    String? name,
    String? hsn,
    int? quantity,
    double? price,
  }) =>
      EditItem(
        key: key,
        productId: productId ?? this.productId,
        name: name ?? this.name,
        hsn: hsn ?? this.hsn,
        quantity: quantity ?? this.quantity,
        price: price ?? this.price,
      );
}

/// Reactive state backing the Edit Quotation form. Plain text fields that do not
/// drive other widgets (title, customer, notes) stay in their own controllers;
/// everything that affects totals, the dropdown or the row list lives here.
class EditQuotationFormState {
  /// Customer picked in the "Select Customer" dropdown (a `GET /customers` id).
  final String? customerId;
  final DateTime date;
  final DateTime validUntil;
  final QuotationStatus status;
  final double taxPercent;
  final List<EditItem> items;

  /// True while `POST /quotations` is in flight — blocks a second submit.
  final bool isSaving;

  const EditQuotationFormState({
    required this.date,
    required this.validUntil,
    required this.status,
    this.customerId,
    this.taxPercent = 0,
    this.items = const [],
    this.isSaving = false,
  });

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.total);
  double get taxAmount => subtotal * taxPercent / 100;
  double get grandTotal => subtotal + taxAmount;

  EditQuotationFormState copyWith({
    String? customerId,
    bool clearCustomer = false,
    DateTime? date,
    DateTime? validUntil,
    QuotationStatus? status,
    double? taxPercent,
    List<EditItem>? items,
    bool? isSaving,
  }) {
    return EditQuotationFormState(
      customerId: clearCustomer ? null : (customerId ?? this.customerId),
      date: date ?? this.date,
      validUntil: validUntil ?? this.validUntil,
      status: status ?? this.status,
      taxPercent: taxPercent ?? this.taxPercent,
      items: items ?? this.items,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class EditQuotationForm extends Notifier<EditQuotationFormState> {
  int _keyCounter = 0;

  @override
  EditQuotationFormState build() => EditQuotationFormState(
        date: DateTime(2020),
        validUntil: DateTime(2020),
        status: QuotationStatus.draft,
      );

  /// Loads the form with the values from [q]. Called once when the screen opens.
  void seed(QuotationModel q) {
    final items = q.items.isEmpty
        ? [EditItem(key: _keyCounter++)]
        : q.items
            .map((i) => EditItem(
                  key: _keyCounter++,
                  name: i.name,
                  hsn: i.hsn,
                  quantity: i.quantity,
                  price: i.price,
                ))
            .toList();
    state = EditQuotationFormState(
      customerId: q.customerId,
      date: q.createdDate,
      validUntil: q.validUntil,
      status: q.status,
      taxPercent: q.taxPercent,
      items: items,
    );
  }

  void setCustomer(String? id) => state = id == null
      ? state.copyWith(clearCustomer: true)
      : state.copyWith(customerId: id);

  void setSaving(bool value) => state = state.copyWith(isSaving: value);

  void setDate(DateTime d) => state = state.copyWith(date: d);

  void setValidUntil(DateTime d) => state = state.copyWith(validUntil: d);

  void setTax(double v) => state = state.copyWith(taxPercent: v);

  void addItem() =>
      state = state.copyWith(items: [...state.items, EditItem(key: _keyCounter++)]);

  void removeItem(int key) {
    final next = state.items.where((i) => i.key != key).toList();
    if (next.isEmpty) next.add(EditItem(key: _keyCounter++));
    state = state.copyWith(items: next);
  }

  void setItemHsn(int key, String hsn) => _patchItem(key, (i) => i.copyWith(hsn: hsn));

  /// Applies a catalog product to a row: its name, HSN and selling price.
  void setItemProduct(
    int key, {
    required int productId,
    required String name,
    required String hsn,
    required double price,
  }) =>
      _patchItem(
        key,
        (i) => i.copyWith(
          productId: productId,
          name: name,
          hsn: hsn,
          price: price,
        ),
      );

  void setItemQuantity(int key, int qty) =>
      _patchItem(key, (i) => i.copyWith(quantity: qty));

  void setItemPrice(int key, double price) =>
      _patchItem(key, (i) => i.copyWith(price: price));

  void _patchItem(int key, EditItem Function(EditItem) update) {
    state = state.copyWith(
      items: [for (final i in state.items) if (i.key == key) update(i) else i],
    );
  }
}

final editQuotationFormProvider =
    NotifierProvider<EditQuotationForm, EditQuotationFormState>(
        EditQuotationForm.new);
