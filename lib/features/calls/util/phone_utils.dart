/// Helpers for comparing phone numbers that may be formatted differently
/// between the CRM (`+91 98765 43210`) and the device call log (`9876543210`).
///
/// The whole call-matching feature hinges on this: a lead's number and the
/// logged number must reduce to the same key or the captured call won't be
/// attributed to the right person.
class PhoneUtils {
  PhoneUtils._();

  /// Canonical comparison key for a phone number: digits only, reduced to the
  /// last 10 digits so country codes / leading zeros / spaces / `+` don't cause
  /// a mismatch (`+91 98765 43210`, `098765 43210` and `9876543210` all map to
  /// `9876543210`). Returns an empty string when there are no digits.
  static String normalize(String? raw) {
    if (raw == null) return '';
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    return digits.length > 10
        ? digits.substring(digits.length - 10)
        : digits;
  }

  /// True when two numbers refer to the same line after [normalize]. An empty /
  /// unparseable number never matches anything.
  static bool sameNumber(String? a, String? b) {
    final na = normalize(a);
    if (na.isEmpty) return false;
    return na == normalize(b);
  }
}
