import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/opportunity_model.dart';

part 'create_quotation_provider.freezed.dart';
part 'create_quotation_provider.g.dart';

/// One editable line on the quotation form. [id] is a stable per-row key so the
/// text fields keep their cursor/scroll position when other rows are added or
/// removed.
@freezed
abstract class QuotationLineDraft with _$QuotationLineDraft {
  const factory QuotationLineDraft({
    required int id,
    @Default('') String description,
    @Default(1) int quantity,
    @Default(0) double price,
  }) = _QuotationLineDraft;

  const QuotationLineDraft._();

  double get lineTotal => quantity * price;
}

/// Transient form state for the "Create Quotation" screen — everything the
/// totals and validation depend on. The free-text fields that feed straight
/// into the model on submit (company / customer / notes) stay on their own
/// [TextEditingController]s.
@freezed
abstract class CreateQuotationFormState with _$CreateQuotationFormState {
  const factory CreateQuotationFormState({
    required DateTime date,
    required DateTime validUntil,
    @Default(18) double taxPercent,
    @Default(<QuotationLineDraft>[]) List<QuotationLineDraft> lines,
    String? error,

    /// Set once the screen has handed over the products it was opened with, so
    /// a rebuild doesn't seed them a second time.
    @Default(false) bool seeded,
  }) = _CreateQuotationFormState;

  const CreateQuotationFormState._();

  double get subtotal =>
      lines.fold<double>(0, (sum, l) => sum + l.lineTotal);

  double get taxAmount => subtotal * taxPercent / 100;

  double get grandTotal => subtotal + taxAmount;
}

/// Holds the "Create Quotation" form state, keyed by opportunity id and
/// auto-disposed so each visit starts fresh. Replaces the screen's local
/// `setState` so the form is Riverpod-managed too.
@riverpod
class CreateQuotationForm extends _$CreateQuotationForm {
  /// Monotonic source of [QuotationLineDraft.id]s — never reused, so a removed
  /// row's id can't collide with a later one.
  int _nextLineId = 0;

  @override
  CreateQuotationFormState build(String opportunityId) {
    final now = DateTime.now();
    return CreateQuotationFormState(
      date: now,
      validUntil: now.add(const Duration(days: 30)),
      lines: [_blankLine()],
    );
  }

  QuotationLineDraft _blankLine() =>
      QuotationLineDraft(id: _nextLineId++);

  /// Seeds the rows from the products the screen was opened with. Runs at most
  /// once; a screen opened with no products keeps the single blank row.
  void seed(List<OpportunityProduct> products) {
    if (state.seeded) return;
    if (products.isEmpty) {
      state = state.copyWith(seeded: true);
      return;
    }
    state = state.copyWith(
      seeded: true,
      lines: [
        for (final p in products)
          QuotationLineDraft(
            id: _nextLineId++,
            description: p.name,
            quantity: p.quantity,
            price: p.price,
          ),
      ],
    );
  }

  void setDate(DateTime v) => state = state.copyWith(date: v);
  void setValidUntil(DateTime v) => state = state.copyWith(validUntil: v);
  void setTaxPercent(double v) => state = state.copyWith(taxPercent: v);
  void setError(String? v) => state = state.copyWith(error: v);

  void addLine() =>
      state = state.copyWith(lines: [...state.lines, _blankLine()]);

  /// Removes a row, falling back to one blank row so the form is never empty.
  void removeLine(int id) {
    final next = state.lines.where((l) => l.id != id).toList();
    state = state.copyWith(
      lines: next.isEmpty ? [_blankLine()] : next,
    );
  }

  void setLineDescription(int id, String v) =>
      _updateLine(id, (l) => l.copyWith(description: v));

  void setLineQuantity(int id, int v) =>
      _updateLine(id, (l) => l.copyWith(quantity: v));

  void setLinePrice(int id, double v) =>
      _updateLine(id, (l) => l.copyWith(price: v));

  void _updateLine(
    int id,
    QuotationLineDraft Function(QuotationLineDraft) change,
  ) {
    state = state.copyWith(
      lines: [
        for (final l in state.lines) if (l.id == id) change(l) else l,
      ],
    );
  }
}
