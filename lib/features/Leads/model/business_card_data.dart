/// Models for the Business-Card / Visiting-Card scanner.
///
/// The OCR engine (ML Kit) and the parsing rules are kept apart on purpose:
/// [OcrLine] is a plain, engine-agnostic value type, so
/// `BusinessCardParser` can be unit-tested against hand-written card layouts
/// without a device or a camera.
library;

/// One recognised line of text on a scanned card, with the geometry needed to
/// reason about layout.
///
/// Geometry matters because a card is a *visual* document: the person's name is
/// usually the largest text, the designation sits directly under it, and the
/// contact block sits apart from both. Text alone can't tell those apart.
class OcrLine {
  /// The recognised text, already whitespace-normalised.
  final String text;

  /// Bounding box of the line in image pixels.
  final double left;
  final double top;
  final double width;
  final double height;

  /// Which captured image this line came from — `0` for the front of the card,
  /// `1` for the back. Sorting keeps the front's lines ahead of the back's.
  final int page;

  const OcrLine({
    required this.text,
    this.left = 0,
    this.top = 0,
    this.width = 0,
    this.height = 0,
    this.page = 0,
  });

  /// Convenience for tests and for cards where the engine gave no geometry.
  factory OcrLine.text(String text, {int page = 0}) =>
      OcrLine(text: text, page: page);

  double get bottom => top + height;
  double get right => left + width;

  OcrLine copyWith({String? text}) => OcrLine(
        text: text ?? this.text,
        left: left,
        top: top,
        width: width,
        height: height,
        page: page,
      );

  @override
  String toString() => 'OcrLine("$text")';
}

/// Everything the parser managed to pull off a card. Every field is a plain
/// string — `''` means "not found on the card", never null, so the review form
/// can bind controllers to it directly.
class BusinessCardData {
  final String firstName;
  final String lastName;

  /// Best guess at the person's mobile number (the one a salesperson calls).
  final String phone;

  /// A second usable number — office line, landline, or a second mobile.
  final String alternatePhone;

  final String email;
  final String company;
  final String designation;
  final String website;

  /// Street address only — [city], [state], [pincode] and [country] have been
  /// carved out of it, so the four can be sent as separate CRM fields.
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String country;

  /// Every line the OCR engine read, in reading order. Shown behind a
  /// "Raw scanned text" expander so nothing on an odd card is silently lost —
  /// the user can always copy a value the parser didn't recognise.
  final List<String> rawLines;

  const BusinessCardData({
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
    this.alternatePhone = '',
    this.email = '',
    this.company = '',
    this.designation = '',
    this.website = '',
    this.address = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.country = '',
    this.rawLines = const [],
  });

  static const BusinessCardData empty = BusinessCardData();

  /// The full recognised text, for the "raw text" panel and for copying.
  String get rawText => rawLines.join('\n');

  String get fullName => [firstName, lastName]
      .where((p) => p.trim().isNotEmpty)
      .join(' ')
      .trim();

  /// How many of the fields the CRM cares about were actually filled — drives
  /// the "7 details captured" summary on the review sheet.
  int get capturedCount => [
        firstName,
        lastName,
        phone,
        alternatePhone,
        email,
        company,
        designation,
        website,
        address,
        city,
        state,
        pincode,
        country,
      ].where((v) => v.trim().isNotEmpty).length;

  /// True when the card yielded nothing worth showing a review form for.
  bool get isEmpty => capturedCount == 0;

  /// True when the essentials a lead needs are present. Used to decide whether
  /// to warn the user before they submit.
  bool get hasContactPoint =>
      phone.trim().isNotEmpty || email.trim().isNotEmpty;

  BusinessCardData copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? alternatePhone,
    String? email,
    String? company,
    String? designation,
    String? website,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? country,
    List<String>? rawLines,
  }) {
    return BusinessCardData(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      email: email ?? this.email,
      company: company ?? this.company,
      designation: designation ?? this.designation,
      website: website ?? this.website,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      country: country ?? this.country,
      rawLines: rawLines ?? this.rawLines,
    );
  }

  @override
  String toString() =>
      'BusinessCardData(name: $fullName, phone: $phone, alt: $alternatePhone, '
      'email: $email, company: $company, designation: $designation, '
      'website: $website, address: $address, city: $city, state: $state, '
      'pincode: $pincode, country: $country)';
}
