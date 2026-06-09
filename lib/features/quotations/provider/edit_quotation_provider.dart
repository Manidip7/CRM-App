import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/quotation_model.dart';

/// One editable line item in the edit form. [key] is a stable identity used for
/// widget keys so rows keep their text-field state across add / remove.
class EditItem {
  final int key;
  final String name;
  final int quantity;
  final double price;

  const EditItem({
    required this.key,
    this.name = '',
    this.quantity = 1,
    this.price = 0,
  });

  double get total => quantity * price;

  EditItem copyWith({String? name, int? quantity, double? price}) => EditItem(
        key: key,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        price: price ?? this.price,
      );
}

/// Reactive state backing the Edit Quotation form. Plain text fields that do not
/// drive other widgets (title, customer, notes) stay in their own controllers;
/// everything that affects totals, the dropdown or the row list lives here.
class EditQuotationFormState {
  final String? opportunityId;
  final DateTime date;
  final DateTime validUntil;
  final QuotationStatus status;
  final double taxPercent;
  final List<EditItem> items;

  const EditQuotationFormState({
    required this.date,
    required this.validUntil,
    required this.status,
    this.opportunityId,
    this.taxPercent = 0,
    this.items = const [],
  });

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.total);
  double get taxAmount => subtotal * taxPercent / 100;
  double get grandTotal => subtotal + taxAmount;

  EditQuotationFormState copyWith({
    String? opportunityId,
    bool clearOpportunity = false,
    DateTime? date,
    DateTime? validUntil,
    QuotationStatus? status,
    double? taxPercent,
    List<EditItem>? items,
  }) {
    return EditQuotationFormState(
      opportunityId:
          clearOpportunity ? null : (opportunityId ?? this.opportunityId),
      date: date ?? this.date,
      validUntil: validUntil ?? this.validUntil,
      status: status ?? this.status,
      taxPercent: taxPercent ?? this.taxPercent,
      items: items ?? this.items,
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
                  quantity: i.quantity,
                  price: i.price,
                ))
            .toList();
    state = EditQuotationFormState(
      opportunityId: q.opportunityId,
      date: q.createdDate,
      validUntil: q.validUntil,
      status: q.status,
      taxPercent: q.taxPercent,
      items: items,
    );
  }

  void setOpportunity(String? id) => state =
      id == null ? state.copyWith(clearOpportunity: true) : state.copyWith(opportunityId: id);

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

  void setItemName(int key, String name) => _patchItem(key, (i) => i.copyWith(name: name));

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
