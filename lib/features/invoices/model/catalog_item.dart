/// A sellable product/service from `GET /items` — what the line-item dropdown
/// on the New Invoice form is built from.
///
/// Two shapes map onto this class, because the backend names the same fields
/// differently in two places:
///
///  * `GET /items` sends `item_name` / `price` / `tax`,
///  * the `item` object nested in an invoice line sends `name` /
///    `selling_price` / `tax_percent` (plus `sku`, `unit`, `is_active`, …).
///
/// [fromJson] reads either, so one model serves both. Money fields arrive as
/// numeric strings ("3600.00") on some rows and as plain numbers on others, so
/// every one goes through [_asDouble].
class CatalogItem {
  final int? id;
  final String name;
  final String? sku;
  final String? hsnNo;
  final String? category;
  final String? unit;
  final String? description;
  final double mrp;
  final double sellingPrice;
  final double taxPercent;
  final bool discountAllowed;
  final double minQty;
  final double stock;
  final bool isActive;
  final String? image;

  /// `selling_price` + tax, as computed by the backend. Falls back to the
  /// locally-derived figure when the API omits it.
  final double? priceAfterTax;

  const CatalogItem({
    required this.name,
    this.id,
    this.sku,
    this.hsnNo,
    this.category,
    this.unit,
    this.description,
    this.mrp = 0,
    this.sellingPrice = 0,
    this.taxPercent = 0,
    this.discountAllowed = true,
    this.minQty = 1,
    this.stock = 0,
    this.isActive = true,
    this.image,
    this.priceAfterTax,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    // `price_after_tax` comes back as 0 from /items, so treat 0 as "not sent"
    // and let [effectivePriceAfterTax] compute it instead.
    final afterTax = _asDouble(json['price_after_tax']);

    return CatalogItem(
      id: _asInt(json['id']),
      name: _asString(json['item_name']) ?? _asString(json['name']) ?? 'Item',
      sku: _asString(json['sku']),
      hsnNo: _asString(json['hsn_no']),
      category: _asString(json['category']),
      unit: _asString(json['unit']),
      description: _asString(json['description']),
      mrp: _asDouble(json['mrp']),
      sellingPrice: _asDouble(json['price'] ?? json['selling_price']),
      taxPercent: _asDouble(json['tax'] ?? json['tax_percent']),
      discountAllowed: json['discount_allowed'] != false,
      minQty: _asDouble(json['min_qty'], fallback: 1),
      stock: _asDouble(json['stock']),
      isActive: json['is_active'] != false,
      image: _asString(json['image']),
      priceAfterTax: afterTax > 0 ? afterTax : null,
    );
  }

  /// Price the line item's UNIT PRICE field is pre-filled with on selection.
  double get defaultPrice => sellingPrice;

  /// Gross-of-tax unit price, preferring the server's own figure.
  double get effectivePriceAfterTax =>
      priceAfterTax ?? sellingPrice * (1 + taxPercent / 100);

  /// The muted second line in the dropdown row — whichever identifying details
  /// the item actually carries, e.g. `PEPLO_CRM · Project · GST 18%` from an
  /// invoice line, or just `GST 18%` from the leaner `/items` payload.
  String? get subtitle {
    final parts = <String>[
      if (sku != null && sku!.isNotEmpty) sku!,
      if (unit != null && unit!.isNotEmpty) unit!,
      if (hsnNo != null && hsnNo!.isNotEmpty) 'HSN $hsnNo',
      if (taxPercent > 0) 'GST ${_trimZeros(taxPercent)}%',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

/// `18.00` → `18`, `2.50` → `2.5`.
String _trimZeros(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? fallback;
  return fallback;
}

int? _asInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}
