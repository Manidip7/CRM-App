import '../model/business_card_data.dart';

/// Turns the raw lines an OCR engine read off a business card into the fields a
/// CRM lead needs.
///
/// Business cards have no schema — a minimalist card is four centred lines, an
/// Indian trader's card is a wall of text with a GSTIN, a Western corporate card
/// puts everything in a right-hand column with `T:` / `M:` / `F:` labels. So the
/// parser never assumes a layout. It runs the extractors in order of certainty:
///
/// 1. **Email, website, phone** — these have hard, checkable shapes, so they are
///    pulled first and the text they consumed is struck out of their lines.
/// 2. **Address** — recognised by street/locality markers, a postal code, or a
///    known state/city name.
/// 3. **Designation** — matched against a job-title vocabulary.
/// 4. **Company** — legal suffixes ("Pvt Ltd", "LLP", "GmbH"), or a line that
///    matches the website/email domain, or the biggest remaining text.
/// 5. **Name** — whatever is left, scored on honorifics, position relative to
///    the designation, text size, word shape, and agreement with the email's
///    local part.
///
/// Every extractor is defensive: none of them is allowed to claim text another
/// has already taken, and each one degrades to a weaker heuristic instead of
/// giving up. A field the card genuinely does not carry comes back as `''`.
class BusinessCardParser {
  const BusinessCardParser._();

  /// Parses [input] — the lines read off one or two images of the same card
  /// (front and back) — into a single [BusinessCardData].
  static BusinessCardData parse(List<OcrLine> input) {
    final lines = _prepare(input);
    if (lines.isEmpty) return const BusinessCardData();

    final ctx = _Ctx(lines);
    _extractEmails(ctx);
    _extractWebsites(ctx);
    _extractPhones(ctx);
    _extractAddress(ctx);
    _extractDesignation(ctx);
    _extractCompany(ctx);
    _extractName(ctx);
    return ctx.build();
  }

  /// Convenience for callers that only have plain text (a pasted card, a test).
  static BusinessCardData parseText(String text) => parse(
        text
            .split('\n')
            .map((l) => OcrLine.text(l))
            .toList(growable: false),
      );

  // ───────────────────────── line preparation ──────────────────────────────

  /// Normalises, orders and stitches the raw OCR lines.
  ///
  /// Ordering matters: ML Kit returns *blocks* in a loose order, so a card's
  /// lines can arrive scrambled. Sorting by vertical position (with a tolerance,
  /// so two labels printed side by side stay on one visual row) restores reading
  /// order, which the name/designation adjacency rules depend on.
  static List<OcrLine> _prepare(List<OcrLine> input) {
    final cleaned = <OcrLine>[];
    for (final line in input) {
      final text = _normalise(line.text);
      if (text.isEmpty) continue;
      // Drop pure decoration — a stray bullet, a rule, a logo fragment.
      if (!RegExp(r'[A-Za-z0-9]').hasMatch(text)) continue;
      if (text.length == 1) continue;
      cleaned.add(line.copyWith(text: text));
    }
    if (cleaned.isEmpty) return const [];

    final hasGeometry = cleaned.any((l) => l.height > 0);
    if (hasGeometry) {
      final heights = cleaned.map((l) => l.height).where((h) => h > 0).toList()
        ..sort();
      final medianHeight = heights[heights.length ~/ 2];
      final rowTolerance = (medianHeight * 0.6).clamp(1.0, double.infinity);
      cleaned.sort((a, b) {
        if (a.page != b.page) return a.page.compareTo(b.page);
        // Same visual row? Then left-to-right; otherwise top-to-bottom.
        if ((a.top - b.top).abs() <= rowTolerance) {
          return a.left.compareTo(b.left);
        }
        return a.top.compareTo(b.top);
      });
    }

    return _stitchWrappedEmails(cleaned);
  }

  /// Rejoins an email the engine broke across two lines — a real failure mode
  /// when a long address is set tight against the card edge
  /// (`"sales@"` / `"acmeindustries.co.in"`).
  static List<OcrLine> _stitchWrappedEmails(List<OcrLine> lines) {
    final out = <OcrLine>[];
    for (var i = 0; i < lines.length; i++) {
      final current = lines[i];
      final next = i + 1 < lines.length ? lines[i + 1] : null;
      final endsOpen = RegExp(r'[A-Za-z0-9._%+\-]@$').hasMatch(current.text);
      final nextIsDomain = next != null &&
          next.page == current.page &&
          RegExp(r'^[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)+$').hasMatch(next.text);
      if (endsOpen && nextIsDomain) {
        out.add(current.copyWith(text: '${current.text}${next.text}'));
        i++; // the domain line has been folded in
        continue;
      }
      out.add(current);
    }
    return out;
  }

  /// Whitespace, look-alike punctuation and stray OCR artefacts.
  static String _normalise(String raw) {
    var text = raw
        .replaceAll(' ', ' ')
        .replaceAll(RegExp(r'[‘’ʼ´`]'), "'")
        .replaceAll(RegExp(r'[“”]'), '"')
        .replaceAll(RegExp(r'[‐-―−⁃]'), '-')
        .replaceAll(RegExp(r'[•●▪·∙■]'), ' ')
        .replaceAll('\t', ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    // Leading/trailing separators left behind by icon glyphs the engine read as
    // punctuation (a phone icon often comes back as ":" or "-"). A leading `+`
    // is deliberately kept — it is the country code of the number that follows.
    text = text.replaceAll(RegExp(r'^[\s:;,.\-|/*=_~^<>]+'), '');
    text = text.replaceAll(RegExp(r'[\s:;|]+$'), '');
    return text.trim();
  }

  // ───────────────────────────── email ─────────────────────────────────────

  static final RegExp _emailRe = RegExp(
    r'[A-Za-z0-9._%+\-]+\s?(?:@|\(at\)|\[at\]|\{at\})\s?[A-Za-z0-9.\-]+\s?\.\s?[A-Za-z]{2,63}',
    caseSensitive: false,
  );

  /// Mailbox names that belong to a company rather than a person. A card with
  /// both `info@` and `rajesh@` should hand the salesperson the personal one.
  static const Set<String> _genericLocals = {
    'info', 'sales', 'contact', 'contactus', 'support', 'enquiry', 'enquiries',
    'inquiry', 'inquiries', 'hello', 'hi', 'office', 'mail', 'email', 'care',
    'customercare', 'help', 'helpdesk', 'service', 'services', 'marketing',
    'accounts', 'account', 'admin', 'hr', 'jobs', 'careers', 'team', 'business',
    'reception', 'feedback', 'orders', 'order', 'booking', 'bookings',
    'noreply', 'no-reply', 'webmaster', 'connect', 'reach', 'query', 'queries',
  };

  /// Free mailbox providers — their domain says nothing about the company, so
  /// the company-from-domain fallback must skip them.
  static const Set<String> _publicMailDomains = {
    'gmail', 'googlemail', 'yahoo', 'ymail', 'rocketmail', 'hotmail', 'outlook',
    'live', 'msn', 'rediffmail', 'rediff', 'icloud', 'me', 'mac', 'aol',
    'protonmail', 'proton', 'zoho', 'zohomail', 'gmx', 'mail', 'yandex',
    'inbox', 'fastmail', 'tutanota', 'hushmail', 'sify', 'vsnl', 'bsnl',
    'airtelmail', 'indiatimes', 'qq', '163', '126',
  };

  static void _extractEmails(_Ctx ctx) {
    final found = <String>[];
    for (var i = 0; i < ctx.lines.length; i++) {
      final text = ctx.lines[i].text;
      for (final match in _emailRe.allMatches(text)) {
        final email = _cleanEmail(match.group(0)!);
        if (email == null) continue;
        ctx.markEmailSpan(i, match.start, match.end);
        ctx.consume(i, _Use.contact);
        if (!found.any((e) => e.toLowerCase() == email)) found.add(email);
      }
    }
    if (found.isEmpty) return;

    // Prefer a personal mailbox over info@/sales@ — that is the human this
    // lead is actually about.
    final personal = found.firstWhere(
      (e) => !_genericLocals.contains(e.split('@').first.toLowerCase()),
      orElse: () => found.first,
    );
    ctx.email = personal;
    ctx.allEmails = found;
  }

  /// Repairs and validates one raw email match.
  static String? _cleanEmail(String raw) {
    var email = raw
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'\((?:at)\)|\[(?:at)\]|\{(?:at)\}',
            caseSensitive: false), '@')
        .toLowerCase();
    email = email.replaceAll(RegExp(r'^[.\-_]+'), '');
    email = email.replaceAll(RegExp(r'[.,;:\-_]+$'), '');

    // Classic OCR confusions inside well-known mail domains. Only applied to
    // the domain half so a person's mailbox name is never rewritten.
    final at = email.indexOf('@');
    if (at <= 0 || at == email.length - 1) return null;
    var local = email.substring(0, at);
    var domain = email.substring(at + 1);
    for (final fix in _domainFixes.entries) {
      domain = domain.replaceAll(fix.key, fix.value);
    }
    email = '$local@$domain';

    final valid = RegExp(r'^[a-z0-9._%+\-]+@[a-z0-9\-]+(\.[a-z0-9\-]+)*\.[a-z]{2,63}$')
        .hasMatch(email);
    if (!valid) return null;
    // A "domain" with no letters is an OCR artefact, not an address.
    if (!RegExp(r'[a-z]').hasMatch(domain.split('.').first)) return null;
    return email;
  }

  static const Map<String, String> _domainFixes = {
    'gmai1': 'gmail', 'gmaii': 'gmail', 'gmall': 'gmail', 'grnail': 'gmail',
    'qmail': 'gmail', 'gmial': 'gmail', 'gmai.': 'gmail.',
    'yah00': 'yahoo', 'yahco': 'yahoo',
    'hotrnail': 'hotmail', 'hotmall': 'hotmail',
    'outiook': 'outlook', 'out1ook': 'outlook',
    'rediffrnail': 'rediffmail',
    '.corn': '.com', '.c0m': '.com', '.con': '.com', '.cotn': '.com',
    '.corri': '.com', '.cnm': '.com',
    '.c0.in': '.co.in', '.co.ln': '.co.in',
  };

  // ──────────────────────────── website ────────────────────────────────────

  /// TLDs accepted for a *bare* domain (no scheme, no `www.`). Kept explicit so
  /// "Mr. Sharma" or "Rev. 2.0" can never be mistaken for a URL.
  static const Set<String> _knownTlds = {
    'com', 'net', 'org', 'in', 'co', 'io', 'ai', 'app', 'dev', 'tech', 'biz',
    'info', 'me', 'us', 'uk', 'ca', 'au', 'nz', 'sg', 'my', 'ae', 'sa', 'qa',
    'om', 'bh', 'kw', 'lk', 'np', 'bd', 'pk', 'de', 'fr', 'it', 'es', 'nl',
    'be', 'ch', 'at', 'se', 'no', 'dk', 'fi', 'pl', 'pt', 'ru', 'cn', 'jp',
    'kr', 'hk', 'tw', 'za', 'ng', 'ke', 'br', 'mx', 'ar', 'cl', 'store',
    'online', 'shop', 'site', 'live', 'life', 'world', 'global', 'group',
    'company', 'agency', 'digital', 'solutions', 'services', 'systems',
    'consulting', 'studio', 'design', 'media', 'network', 'cloud', 'software',
    'academy', 'institute', 'education', 'clinic', 'health', 'care', 'law',
    'finance', 'capital', 'energy', 'travel', 'hotel', 'club', 'xyz', 'pro',
    'ltd', 'llc', 'inc', 'today', 'link', 'page', 'website', 'space', 'fun',
  };

  static final RegExp _schemeUrlRe = RegExp(
    r'(?:https?://|www\.)[A-Za-z0-9\-._~%]+\.[A-Za-z]{2,63}(?:/[^\s,;|)\]]*)?',
    caseSensitive: false,
  );

  static final RegExp _bareDomainRe = RegExp(
    r'\b[A-Za-z0-9][A-Za-z0-9\-]{1,62}(?:\.[A-Za-z0-9\-]{2,63})*\.([A-Za-z]{2,63})\b(?:/[^\s,;|)\]]*)?',
  );

  static void _extractWebsites(_Ctx ctx) {
    final found = <String>[];

    void take(int index, RegExpMatch match, {required bool requireKnownTld}) {
      // Never re-read an email's domain as the company website.
      if (ctx.overlapsEmail(index, match.start, match.end)) return;
      final text = ctx.lines[index].text;
      if (match.start > 0 && text[match.start - 1] == '@') return;

      final url = _cleanUrl(match.group(0)!, requireKnownTld: requireKnownTld);
      if (url == null) return;
      ctx.markUrlSpan(index, match.start, match.end);
      ctx.consume(index, _Use.contact);
      if (!found.contains(url)) found.add(url);
    }

    for (var i = 0; i < ctx.lines.length; i++) {
      final text = ctx.lines[i].text;
      for (final m in _schemeUrlRe.allMatches(text)) {
        take(i, m, requireKnownTld: false);
      }
      for (final m in _bareDomainRe.allMatches(text)) {
        // Skip anything already covered by the scheme pass.
        if (ctx.overlapsUrl(i, m.start, m.end)) continue;
        take(i, m, requireKnownTld: true);
      }
    }

    if (found.isEmpty) return;
    // A company site beats a social profile if the card carries both.
    const social = {'facebook', 'linkedin', 'instagram', 'twitter', 'x.com',
      'youtube', 'wa.me', 'whatsapp', 't.me', 'telegram', 'pinterest'};
    final primary = found.firstWhere(
      (u) => !social.any((s) => u.contains(s)),
      orElse: () => found.first,
    );
    ctx.website = primary;
  }

  static String? _cleanUrl(String raw, {required bool requireKnownTld}) {
    var url = raw.trim().toLowerCase();
    url = url.replaceAll(RegExp(r'[.,;:)\]]+$'), '');
    for (final fix in _domainFixes.entries) {
      url = url.replaceAll(fix.key, fix.value);
    }
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    final host = url
        .replaceFirst(RegExp(r'^https?://'), '')
        .split('/')
        .first;
    final labels = host.split('.');
    if (labels.length < 2) return null;
    final tld = labels.last;
    if (requireKnownTld && !_knownTlds.contains(tld)) return null;
    if (tld.length < 2) return null;
    // A "domain" whose name half is all digits is a mis-read number.
    if (!RegExp(r'[a-z]').hasMatch(labels[labels.length - 2])) return null;
    return url;
  }

  // ───────────────────────────── phones ────────────────────────────────────

  /// Segment separators. Cards routinely stack two numbers on one line
  /// (`"+91 98200 11111 / 22222 33333"`), and each half can carry its own label.
  static final RegExp _segmentSplitRe =
      RegExp(r'\s*(?:[/|]|,|;|\band\b|&)\s*', caseSensitive: false);

  static final RegExp _phoneCandidateRe =
      RegExp(r'\+?\d[\d\s\-().]{5,}\d');

  /// Registration numbers that look like phone numbers but never are.
  static final RegExp _idNoiseRe = RegExp(
    r'\b(gst(?:in)?|pan|cin|tan|ifsc|udyam|udyog|msme|ssi|fssai|tin|vat|cst|'
    r'iec|din|dl\s*no|reg(?:d|n|istration)?\.?\s*no|licen[cs]e|a/?c\s*no|'
    r'account\s*no|aadhaar|aadhar|passport|invoice|bill\s*no)\b',
    caseSensitive: false,
  );

  static void _extractPhones(_Ctx ctx) {
    final numbers = <_Phone>[];

    for (var i = 0; i < ctx.lines.length; i++) {
      final text = ctx.lines[i].text;
      var cursor = 0;
      for (final segment in text.split(_segmentSplitRe)) {
        final start = text.indexOf(segment, cursor);
        final offset = start < 0 ? cursor : start;
        cursor = offset + segment.length;
        if (segment.trim().isEmpty) continue;
        if (_idNoiseRe.hasMatch(segment)) continue;

        for (final m in _phoneCandidateRe.allMatches(segment)) {
          final absStart = offset + m.start;
          final absEnd = offset + m.end;
          if (ctx.overlapsEmail(i, absStart, absEnd)) continue;
          if (ctx.overlapsUrl(i, absStart, absEnd)) continue;

          final formatted = _formatPhone(m.group(0)!);
          if (formatted == null) continue;
          final kind = _phoneKind(segment.substring(0, m.start), text, formatted);
          final value = _stripTrunkZero(formatted, kind);
          final key = _phoneKey(value);
          if (numbers.any((p) => p.key == key)) {
            ctx.markPhoneSpan(i, absStart, absEnd);
            continue;
          }
          numbers.add(_Phone(value, kind, key));
          ctx.markPhoneSpan(i, absStart, absEnd);
          ctx.consume(i, _Use.contact);
        }
      }
    }
    if (numbers.isEmpty) return;

    // Order by how useful the number is to a salesperson: a mobile they can
    // call or WhatsApp first, a desk line next, a fax only if nothing else.
    int rank(_Phone p) => switch (p.kind) {
          _PhoneKind.mobile => 0,
          _PhoneKind.unknown => 1,
          _PhoneKind.landline => 2,
          _PhoneKind.tollFree => 3,
          _PhoneKind.fax => 4,
        };
    final sorted = [...numbers];
    // Stable sort keeps the card's own order inside a rank.
    sorted.sort((a, b) => rank(a).compareTo(rank(b)));

    ctx.phone = sorted.first.value;
    if (sorted.length > 1) ctx.alternatePhone = sorted[1].value;
  }

  /// Classifies a number from the label printed before it, falling back to the
  /// number's own shape.
  static _PhoneKind _phoneKind(String before, String wholeLine, String number) {
    final label = before.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    // Longest, most specific words first — "telefax" must not read as "tel".
    if (label.contains('telefax') || label.contains('fax')) {
      return _PhoneKind.fax;
    }
    if (label.contains('whatsapp') ||
        label.contains('wapp') ||
        label.contains('mobile') ||
        label.contains('mob') ||
        label.contains('cell') ||
        label.contains('handphone') ||
        label.contains('handy')) {
      return _PhoneKind.mobile;
    }
    if (label.contains('tollfree') || label.contains('toll')) {
      return _PhoneKind.tollFree;
    }
    if (label.contains('tel') ||
        label.contains('phone') ||
        label.contains('office') ||
        label.contains('landline') ||
        label.contains('resi') ||
        label.contains('direct') ||
        label.contains('board')) {
      return _PhoneKind.landline;
    }
    // Single-letter labels: the near-universal card shorthand.
    switch (label) {
      case 'm':
      case 'mo':
      case 'c':
      case 'hp':
        return _PhoneKind.mobile;
      case 'f':
        return _PhoneKind.fax;
      case 't':
      case 'p':
      case 'o':
      case 'd':
      case 'w':
      case 'b':
      case 'ph':
      case 'off':
      case 'res':
      case 'll':
        return _PhoneKind.landline;
    }
    // No label on this number, but the line may still be labelled once at its
    // start ("Mob: 98200 11111 / 98200 22222").
    if (before.trim().isEmpty) {
      final lineLabel = wholeLine.toLowerCase();
      if (RegExp(r'^\s*(m|mob|mobile|cell)\b').hasMatch(lineLabel)) {
        return _PhoneKind.mobile;
      }
      if (RegExp(r'^\s*(f|fax)\b').hasMatch(lineLabel)) return _PhoneKind.fax;
    }
    return _shapeKind(number);
  }

  /// Shape-based guess for an unlabelled number.
  static _PhoneKind _shapeKind(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    // A trunk-prefixed 11-digit Indian number is ambiguous: "09876543210" is a
    // mobile, but "08023456789" is Bangalore. Only a following 9 is unique to
    // mobiles — the rest are treated as landlines so the 0 is never stripped
    // off an area code.
    if (!number.startsWith('+') && digits.length == 11 && digits[0] == '0') {
      return digits[1] == '9' ? _PhoneKind.mobile : _PhoneKind.landline;
    }
    final national = _national(number);
    if (national.startsWith('1800') ||
        national.startsWith('1860') ||
        national.startsWith('800') && national.length <= 10) {
      return _PhoneKind.tollFree;
    }
    // India: a 10-digit number starting 6-9 is a mobile, always.
    if (national.length == 10 && RegExp(r'^[6-9]').hasMatch(national)) {
      return _PhoneKind.mobile;
    }
    // UK / many EU: national numbers beginning 7 (mobile) after the trunk 0.
    if (number.startsWith('+44') && national.startsWith('7')) {
      return _PhoneKind.mobile;
    }
    if (digits.length <= 8) return _PhoneKind.landline;
    return _PhoneKind.unknown;
  }

  /// Country codes we recognise when a number is written with a leading `+`.
  /// Matched longest-first so `+971` is not read as `+97`.
  static const List<String> _countryCodes = [
    '971', '972', '973', '974', '975', '976', '977', '966', '968', '962',
    '965', '961', '964', '960', '880', '886', '852', '853', '855', '856',
    '351', '352', '353', '358', '359', '370', '371', '372', '380', '381',
    '385', '386', '387', '389', '420', '421', '212', '213', '216', '218',
    '234', '254', '255', '256', '260', '263', '992', '993', '994', '995',
    '996', '998', '20', '27', '30', '31', '32', '33', '34', '36', '39', '40',
    '41', '43', '44', '45', '46', '47', '48', '49', '51', '52', '54', '55',
    '56', '57', '58', '60', '61', '62', '63', '64', '65', '66', '81', '82',
    '84', '86', '90', '91', '92', '93', '94', '95', '98', '1', '7',
  ];

  /// The subscriber part of a number, with country code and trunk `0` removed.
  static String _national(String formatted) {
    var digits = formatted.replaceAll(RegExp(r'\D'), '');
    if (formatted.trimLeft().startsWith('+')) {
      for (final cc in _countryCodes) {
        if (digits.startsWith(cc) && digits.length > cc.length + 5) {
          digits = digits.substring(cc.length);
          break;
        }
      }
    } else if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    while (digits.length > 10 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  /// Validates a candidate and rewrites it into a single canonical form —
  /// `+91 9876543210` or `9876543210`. Returns null when it isn't a phone
  /// number at all.
  static String? _formatPhone(String raw) {
    final hasPlus = raw.trimLeft().startsWith('+');
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 15) return null;
    // 6 digits is an Indian PIN code; a run of one repeated digit is a rule or
    // a fax header the engine mis-read.
    if (RegExp(r'^(\d)\1+$').hasMatch(digits)) return null;
    // A bare 8-digit run that looks like a date (20240115) is not a number.
    if (!hasPlus &&
        digits.length == 8 &&
        RegExp(r'^(19|20)\d{6}$').hasMatch(digits)) {
      return null;
    }

    if (hasPlus) {
      for (final cc in _countryCodes) {
        if (digits.startsWith(cc) && digits.length > cc.length + 5) {
          return '+$cc ${digits.substring(cc.length)}';
        }
      }
      return '+$digits';
    }
    // Indian numbers are commonly printed as "91 98765 43210" without the plus.
    if (digits.length == 12 && RegExp(r'^91[6-9]').hasMatch(digits)) {
      return '+91 ${digits.substring(2)}';
    }
    // A leading trunk `0` is left alone here — only [_stripTrunkZero] removes
    // it, and only once the number is known to be a mobile. "080 2345 6789" is
    // a Bangalore landline whose leading 0 is part of the STD code.
    return digits;
  }

  /// Drops the Indian trunk prefix from a number that is known to be a mobile,
  /// so "0 98765 43210" is stored the way it is dialled: "9876543210".
  static String _stripTrunkZero(String value, _PhoneKind kind) {
    if (kind != _PhoneKind.mobile) return value;
    if (value.startsWith('+')) return value;
    if (value.length == 11 && RegExp(r'^0[6-9]').hasMatch(value)) {
      return value.substring(1);
    }
    return value;
  }

  /// Two printings of the same number (with and without country code) must
  /// collapse to one entry, so numbers are de-duplicated on their tail.
  static String _phoneKey(String formatted) {
    final digits = formatted.replaceAll(RegExp(r'\D'), '');
    return digits.length <= 9 ? digits : digits.substring(digits.length - 9);
  }

  // ───────────────────────────── address ───────────────────────────────────

  /// Words that identify a postal address on their own.
  static final RegExp _strongAddressRe = RegExp(
    r'\b(road|street|lane|marg|nagar|colony|sector|plot|flat|floor|building|'
    r'bldg|tower|complex|avenue|highway|layout|opposite|opp|near|behind|beside|'
    r'landmark|enclave|chowk|cross|phase|taluka|tehsil|district|dist|pincode|'
    r'pin\s*code|zip|p\.?\s?o\.?\s*box|post\s*box|apartment|apartments|'
    r'industrial\s*(area|estate)|midc|gidc|sidco|hsiidc|premises|godown|'
    r'warehouse|factory|survey\s*no|khasra|mouza|vihar|puram|mohalla|gali|'
    r'bazaar|bazar|peth|wadi|halli|palya|pura|ganj)\b',
    caseSensitive: false,
  );

  /// Weaker hints — only count when the line also carries a digit or a comma,
  /// so "Park Avenue Consulting" is not filed as an address.
  static final RegExp _weakAddressRe = RegExp(
    r'\b(rd|st|ave|blvd|no|unit|suite|room|door|house|park|market|city|town|'
    r'village|square|circle|extension|extn|heights|residency|society|soc|'
    r'estate|arcade|plaza|chambers|villa|wing|block|main|centre|center|'
    r'campus|annexe|annex|bhavan|bhawan|sadan|niwas|nivas|mansion)\b',
    caseSensitive: false,
  );

  /// Labels a card prints in front of its address, stripped before storing.
  static final RegExp _addressLabelRe = RegExp(
    r'^\s*(addr(?:ess)?|add|office\s*add(?:ress)?|regd?\.?\s*(?:office|add(?:ress)?)?|'
    r'registered\s*office|corp(?:orate)?\.?\s*office|head\s*office|h\.?\s?o\.?|'
    r'branch(?:\s*office)?|works|factory|showroom|store|studio|clinic|location)'
    r'\s*[:\-–]\s*',
    caseSensitive: false,
  );

  static final RegExp _indiaPinRe = RegExp(r'\b[1-9]\d{2}\s?\d{3}\b');
  static final RegExp _usZipRe = RegExp(r'\b\d{5}(?:-\d{4})?\b');
  static final RegExp _ukPostcodeRe = RegExp(
    r'\b[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2}\b',
  );

  /// A US state code immediately followed by a ZIP — the only shape in which a
  /// bare two-letter abbreviation is safe to read as a state.
  static final RegExp _usStateZipRe =
      RegExp(r'\b([A-Z]{2})\b[\s,]*(\d{5}(?:-\d{4})?)\b');

  static const Map<String, String> _usStates = {
    'AL': 'Alabama', 'AK': 'Alaska', 'AZ': 'Arizona', 'AR': 'Arkansas',
    'CA': 'California', 'CO': 'Colorado', 'CT': 'Connecticut',
    'DE': 'Delaware', 'DC': 'District of Columbia', 'FL': 'Florida',
    'GA': 'Georgia', 'HI': 'Hawaii', 'ID': 'Idaho', 'IL': 'Illinois',
    'IN': 'Indiana', 'IA': 'Iowa', 'KS': 'Kansas', 'KY': 'Kentucky',
    'LA': 'Louisiana', 'ME': 'Maine', 'MD': 'Maryland',
    'MA': 'Massachusetts', 'MI': 'Michigan', 'MN': 'Minnesota',
    'MS': 'Mississippi', 'MO': 'Missouri', 'MT': 'Montana',
    'NE': 'Nebraska', 'NV': 'Nevada', 'NH': 'New Hampshire',
    'NJ': 'New Jersey', 'NM': 'New Mexico', 'NY': 'New York',
    'NC': 'North Carolina', 'ND': 'North Dakota', 'OH': 'Ohio',
    'OK': 'Oklahoma', 'OR': 'Oregon', 'PA': 'Pennsylvania',
    'RI': 'Rhode Island', 'SC': 'South Carolina', 'SD': 'South Dakota',
    'TN': 'Tennessee', 'TX': 'Texas', 'UT': 'Utah', 'VT': 'Vermont',
    'VA': 'Virginia', 'WA': 'Washington', 'WV': 'West Virginia',
    'WI': 'Wisconsin', 'WY': 'Wyoming',
  };

  static void _extractAddress(_Ctx ctx) {
    final flags = List<bool>.filled(ctx.lines.length, false);

    for (var i = 0; i < ctx.lines.length; i++) {
      // A line already fully spent on contact details is not an address, but a
      // line that merely *contained* a phone number may still be one
      // ("12 MG Road, Pune - 411001, Ph: 020 2233 4455").
      final residual = ctx.residual(i);
      if (residual.trim().length < 4) continue;
      flags[i] = _looksLikeAddress(residual);
    }

    // A line wedged between two address lines belongs to the address even when
    // it carries no marker of its own ("Andheri East" between a street and a
    // PIN line).
    for (var i = 1; i < flags.length - 1; i++) {
      if (!flags[i] &&
          flags[i - 1] &&
          flags[i + 1] &&
          ctx.lines[i].page == ctx.lines[i - 1].page &&
          !ctx.isConsumed(i, _Use.contact)) {
        flags[i] = true;
      }
    }
    // The line right after an address block is often just "City - 400069" or a
    // bare state name.
    for (var i = 1; i < flags.length; i++) {
      if (flags[i] || !flags[i - 1]) continue;
      if (ctx.lines[i].page != ctx.lines[i - 1].page) continue;
      final residual = ctx.residual(i);
      if (residual.isEmpty) continue;
      if (_indiaPinRe.hasMatch(residual) ||
          _matchState(residual) != null ||
          _matchCountry(residual) != null) {
        flags[i] = true;
      }
    }

    final parts = <String>[];
    for (var i = 0; i < flags.length; i++) {
      if (!flags[i]) continue;
      ctx.consume(i, _Use.address);
      final piece = ctx.residual(i).replaceFirst(_addressLabelRe, '').trim();
      if (piece.isNotEmpty) parts.add(piece);
    }
    if (parts.isEmpty) return;

    var full = parts.join(', ');
    full = _tidySeparators(full);
    ctx.address = _splitLocality(full, ctx);
  }

  static bool _looksLikeAddress(String text) {
    if (_addressLabelRe.hasMatch(text)) return true;
    if (_strongAddressRe.hasMatch(text)) return true;

    final hasDigit = RegExp(r'\d').hasMatch(text);
    final hasComma = text.contains(',') || text.contains('-');
    if (_weakAddressRe.hasMatch(text) && (hasDigit || hasComma)) return true;

    // A standalone postal code, with or without a city beside it.
    final pinOnly = _indiaPinRe.stringMatch(text);
    if (pinOnly != null && text.replaceAll(pinOnly, '').trim().length < 40) {
      return true;
    }
    if (_matchState(text) != null) return true;
    if (_matchCity(text) != null && (hasDigit || hasComma)) return true;
    // "42, MG Cross" — a leading house number followed by words.
    if (RegExp(r'^\d{1,5}\s*[,\-/]\s*\D{3,}').hasMatch(text)) return true;
    return false;
  }

  /// Carves city / state / PIN / country out of the joined address text and
  /// returns what is left as the street address.
  static String _splitLocality(String full, _Ctx ctx) {
    var rest = full;

    final country = _matchCountry(rest);
    if (country != null) {
      ctx.country = country.canonical;
      rest = _removeSpan(rest, country.start, country.end);
    }

    // PIN / ZIP / postcode. India first — this CRM's cards are mostly Indian —
    // then the international shapes.
    final pin = _indiaPinRe.firstMatch(rest);
    if (pin != null) {
      ctx.pincode = pin.group(0)!.replaceAll(' ', '');
      rest = _removeSpan(rest, pin.start, pin.end);
    } else {
      // "Austin, TX 78701" — the two-letter state is only trusted when a ZIP
      // follows it, so an ordinary word like "IN" or "OR" can't be misread.
      final us = _usStateZipRe.firstMatch(rest);
      final uk = _ukPostcodeRe.firstMatch(rest.toUpperCase());
      final zip = _usZipRe.firstMatch(rest);
      if (us != null && _usStates.containsKey(us.group(1))) {
        ctx.state = _usStates[us.group(1)]!;
        ctx.pincode = us.group(2)!;
        rest = _removeSpan(rest, us.start, us.end);
      } else if (uk != null) {
        ctx.pincode = rest.substring(uk.start, uk.end).trim();
        rest = _removeSpan(rest, uk.start, uk.end);
      } else if (zip != null) {
        ctx.pincode = zip.group(0)!;
        rest = _removeSpan(rest, zip.start, zip.end);
      }
    }

    final state = _matchState(rest);
    if (state != null) {
      ctx.state = state.canonical;
      rest = _removeSpan(rest, state.start, state.end);
    }

    final city = _matchCity(rest);
    if (city != null) {
      ctx.city = city.canonical;
      rest = _removeSpan(rest, city.start, city.end);
    } else {
      // No city from the gazetteer — fall back to the trailing comma-segment,
      // which is where a city almost always sits.
      final segments = rest
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (segments.length > 1) {
        final last = segments.last;
        final plausible = last.split(' ').length <= 3 &&
            !RegExp(r'\d').hasMatch(last) &&
            !_strongAddressRe.hasMatch(last) &&
            last.length > 2;
        if (plausible) {
          ctx.city = _titleCase(last);
          segments.removeLast();
          rest = segments.join(', ');
        }
      }
    }

    // An Indian PIN implies the country even when the card doesn't print it.
    if (ctx.country.isEmpty && ctx.pincode.length == 6 && ctx.state.isNotEmpty) {
      ctx.country = 'India';
    }

    return _tidySeparators(rest);
  }

  static String _removeSpan(String text, int start, int end) =>
      text.substring(0, start) + text.substring(end);

  /// Collapses the empty commas and dangling dashes left behind once city,
  /// state and PIN have been lifted out.
  static String _tidySeparators(String text) {
    var out = text.replaceAll(RegExp(r'\s+'), ' ');
    out = out.replaceAll(RegExp(r'(\s*[,\-–]\s*){2,}'), ', ');
    out = out.replaceAll(RegExp(r'^[\s,\-–.]+'), '');
    out = out.replaceAll(RegExp(r'[\s,\-–]+$'), '');
    return out.trim();
  }

  // ─────────────────────────── gazetteers ──────────────────────────────────

  /// Indian states and union territories, plus the spellings and old names
  /// still printed on cards. Key = what to look for, value = what to store.
  static const Map<String, String> _states = {
    'andhra pradesh': 'Andhra Pradesh',
    'arunachal pradesh': 'Arunachal Pradesh',
    'assam': 'Assam',
    'bihar': 'Bihar',
    'chhattisgarh': 'Chhattisgarh',
    'chattisgarh': 'Chhattisgarh',
    'goa': 'Goa',
    'gujarat': 'Gujarat',
    'haryana': 'Haryana',
    'himachal pradesh': 'Himachal Pradesh',
    'jharkhand': 'Jharkhand',
    'karnataka': 'Karnataka',
    'kerala': 'Kerala',
    'madhya pradesh': 'Madhya Pradesh',
    'maharashtra': 'Maharashtra',
    'manipur': 'Manipur',
    'meghalaya': 'Meghalaya',
    'mizoram': 'Mizoram',
    'nagaland': 'Nagaland',
    'odisha': 'Odisha',
    'orissa': 'Odisha',
    'punjab': 'Punjab',
    'rajasthan': 'Rajasthan',
    'sikkim': 'Sikkim',
    'tamil nadu': 'Tamil Nadu',
    'tamilnadu': 'Tamil Nadu',
    'telangana': 'Telangana',
    'tripura': 'Tripura',
    'uttar pradesh': 'Uttar Pradesh',
    'uttarakhand': 'Uttarakhand',
    'uttaranchal': 'Uttarakhand',
    'west bengal': 'West Bengal',
    'andaman and nicobar': 'Andaman and Nicobar Islands',
    'chandigarh': 'Chandigarh',
    'dadra and nagar haveli': 'Dadra and Nagar Haveli and Daman and Diu',
    'daman and diu': 'Dadra and Nagar Haveli and Daman and Diu',
    'new delhi': 'Delhi',
    'delhi': 'Delhi',
    'jammu and kashmir': 'Jammu and Kashmir',
    'jammu & kashmir': 'Jammu and Kashmir',
    'ladakh': 'Ladakh',
    'lakshadweep': 'Lakshadweep',
    'puducherry': 'Puducherry',
    'pondicherry': 'Puducherry',
  };

  /// Cities frequent enough on Indian and Gulf business cards to be worth
  /// matching by name. Anything not listed still gets caught by the
  /// "last comma-segment" fallback in [_splitLocality].
  static const Map<String, String> _cities = {
    'mumbai': 'Mumbai', 'bombay': 'Mumbai', 'navi mumbai': 'Navi Mumbai',
    'thane': 'Thane', 'pune': 'Pune', 'nagpur': 'Nagpur', 'nashik': 'Nashik',
    'nasik': 'Nashik', 'aurangabad': 'Aurangabad', 'solapur': 'Solapur',
    'kolhapur': 'Kolhapur', 'amravati': 'Amravati', 'sangli': 'Sangli',
    'delhi': 'Delhi', 'new delhi': 'New Delhi', 'noida': 'Noida',
    'greater noida': 'Greater Noida', 'gurgaon': 'Gurgaon',
    'gurugram': 'Gurugram', 'faridabad': 'Faridabad', 'ghaziabad': 'Ghaziabad',
    'sonipat': 'Sonipat', 'panipat': 'Panipat', 'karnal': 'Karnal',
    'bengaluru': 'Bengaluru', 'bangalore': 'Bengaluru', 'mysuru': 'Mysuru',
    'mysore': 'Mysuru', 'mangaluru': 'Mangaluru', 'mangalore': 'Mangaluru',
    'hubli': 'Hubli', 'belgaum': 'Belagavi', 'belagavi': 'Belagavi',
    'chennai': 'Chennai', 'madras': 'Chennai', 'coimbatore': 'Coimbatore',
    'madurai': 'Madurai', 'tiruchirappalli': 'Tiruchirappalli',
    'trichy': 'Tiruchirappalli', 'salem': 'Salem', 'erode': 'Erode',
    'tirupur': 'Tiruppur', 'tiruppur': 'Tiruppur', 'vellore': 'Vellore',
    'hyderabad': 'Hyderabad', 'secunderabad': 'Secunderabad',
    'warangal': 'Warangal', 'vijayawada': 'Vijayawada',
    'visakhapatnam': 'Visakhapatnam', 'vizag': 'Visakhapatnam',
    'guntur': 'Guntur', 'tirupati': 'Tirupati', 'nellore': 'Nellore',
    'kolkata': 'Kolkata', 'calcutta': 'Kolkata', 'howrah': 'Howrah',
    'siliguri': 'Siliguri', 'durgapur': 'Durgapur', 'asansol': 'Asansol',
    'ahmedabad': 'Ahmedabad', 'surat': 'Surat', 'vadodara': 'Vadodara',
    'baroda': 'Vadodara', 'rajkot': 'Rajkot', 'bhavnagar': 'Bhavnagar',
    'jamnagar': 'Jamnagar', 'gandhinagar': 'Gandhinagar', 'anand': 'Anand',
    'jaipur': 'Jaipur', 'jodhpur': 'Jodhpur', 'udaipur': 'Udaipur',
    'kota': 'Kota', 'ajmer': 'Ajmer', 'bikaner': 'Bikaner',
    'lucknow': 'Lucknow', 'kanpur': 'Kanpur', 'agra': 'Agra',
    'varanasi': 'Varanasi', 'prayagraj': 'Prayagraj', 'allahabad': 'Prayagraj',
    'meerut': 'Meerut', 'bareilly': 'Bareilly', 'aligarh': 'Aligarh',
    'gorakhpur': 'Gorakhpur', 'moradabad': 'Moradabad',
    'indore': 'Indore', 'bhopal': 'Bhopal', 'jabalpur': 'Jabalpur',
    'gwalior': 'Gwalior', 'ujjain': 'Ujjain',
    'patna': 'Patna', 'gaya': 'Gaya', 'muzaffarpur': 'Muzaffarpur',
    'ranchi': 'Ranchi', 'jamshedpur': 'Jamshedpur', 'dhanbad': 'Dhanbad',
    'bhubaneswar': 'Bhubaneswar', 'cuttack': 'Cuttack',
    'rourkela': 'Rourkela', 'raipur': 'Raipur', 'bhilai': 'Bhilai',
    'chandigarh': 'Chandigarh', 'ludhiana': 'Ludhiana',
    'amritsar': 'Amritsar', 'jalandhar': 'Jalandhar', 'mohali': 'Mohali',
    'panchkula': 'Panchkula', 'dehradun': 'Dehradun', 'haridwar': 'Haridwar',
    'shimla': 'Shimla', 'jammu': 'Jammu', 'srinagar': 'Srinagar',
    'kochi': 'Kochi', 'cochin': 'Kochi', 'ernakulam': 'Ernakulam',
    'thiruvananthapuram': 'Thiruvananthapuram',
    'trivandrum': 'Thiruvananthapuram', 'kozhikode': 'Kozhikode',
    'calicut': 'Kozhikode', 'thrissur': 'Thrissur', 'kollam': 'Kollam',
    'guwahati': 'Guwahati', 'shillong': 'Shillong', 'imphal': 'Imphal',
    'agartala': 'Agartala', 'aizawl': 'Aizawl', 'itanagar': 'Itanagar',
    'panaji': 'Panaji', 'margao': 'Margao', 'vasco': 'Vasco da Gama',
    'puducherry': 'Puducherry', 'pondicherry': 'Puducherry',
    'dubai': 'Dubai', 'abu dhabi': 'Abu Dhabi', 'sharjah': 'Sharjah',
    'doha': 'Doha', 'muscat': 'Muscat', 'riyadh': 'Riyadh',
    'jeddah': 'Jeddah', 'manama': 'Manama', 'kuwait city': 'Kuwait City',
    'singapore': 'Singapore', 'kuala lumpur': 'Kuala Lumpur',
    'bangkok': 'Bangkok', 'colombo': 'Colombo', 'kathmandu': 'Kathmandu',
    'dhaka': 'Dhaka', 'karachi': 'Karachi', 'lahore': 'Lahore',
    'london': 'London', 'manchester': 'Manchester', 'birmingham':
        'Birmingham', 'new york': 'New York', 'chicago': 'Chicago',
    'houston': 'Houston', 'san francisco': 'San Francisco',
    'los angeles': 'Los Angeles', 'toronto': 'Toronto',
    'vancouver': 'Vancouver', 'sydney': 'Sydney', 'melbourne': 'Melbourne',
  };

  static const Map<String, String> _countries = {
    'india': 'India', 'bharat': 'India',
    'united arab emirates': 'United Arab Emirates', 'u.a.e': 'United Arab Emirates',
    'uae': 'United Arab Emirates',
    'saudi arabia': 'Saudi Arabia', 'ksa': 'Saudi Arabia',
    'qatar': 'Qatar', 'oman': 'Oman', 'kuwait': 'Kuwait',
    'bahrain': 'Bahrain', 'singapore': 'Singapore', 'malaysia': 'Malaysia',
    'thailand': 'Thailand', 'sri lanka': 'Sri Lanka', 'nepal': 'Nepal',
    'bangladesh': 'Bangladesh', 'pakistan': 'Pakistan',
    'united kingdom': 'United Kingdom', 'u.k': 'United Kingdom',
    'england': 'United Kingdom',
    'united states': 'United States', 'u.s.a': 'United States',
    'usa': 'United States', 'canada': 'Canada', 'australia': 'Australia',
    'new zealand': 'New Zealand', 'germany': 'Germany', 'france': 'France',
    'italy': 'Italy', 'spain': 'Spain', 'netherlands': 'Netherlands',
    'switzerland': 'Switzerland', 'china': 'China', 'japan': 'Japan',
    'south africa': 'South Africa', 'kenya': 'Kenya', 'nigeria': 'Nigeria',
  };

  static _Gazetteer? _matchState(String text) =>
      _matchGazetteer(text, _states);

  static _Gazetteer? _matchCity(String text) => _matchGazetteer(text, _cities);

  static _Gazetteer? _matchCountry(String text) =>
      _matchGazetteer(text, _countries);

  /// Longest-first whole-word lookup, so "New Delhi" wins over "Delhi" and
  /// "Navi Mumbai" over "Mumbai".
  static _Gazetteer? _matchGazetteer(String text, Map<String, String> table) {
    final keys = table.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final lower = text.toLowerCase();
    for (final key in keys) {
      final pattern = RegExp(
        '(?<![a-z])${RegExp.escape(key)}(?![a-z])',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(lower);
      if (match != null) {
        return _Gazetteer(table[key]!, match.start, match.end);
      }
    }
    return null;
  }

  // ─────────────────────────── designation ─────────────────────────────────

  static final RegExp _designationRe = RegExp(
    r'\b('
    r'ceo|cto|cfo|coo|cmo|cio|cxo|md|managing\s*director|executive\s*director|'
    r'director|dy\.?\s*director|joint\s*director|chairman|chairperson|'
    r'president|vice\s*president|vp|avp|svp|evp|founder|co-?founder|'
    r'proprietor|prop|partner|owner|principal|head|group\s*head|'
    r'general\s*manager|gm|dgm|agm|manager|asst\.?\s*manager|'
    r'assistant\s*manager|deputy\s*manager|senior\s*manager|sr\.?\s*manager|'
    r'branch\s*manager|area\s*manager|regional\s*manager|zonal\s*manager|'
    r'territory\s*manager|product\s*manager|project\s*manager|account\s*manager|'
    r'relationship\s*manager|business\s*(development|head)|bdm|bde|'
    r'executive|sr\.?\s*executive|senior\s*executive|officer|'
    r'engineer|sr\.?\s*engineer|senior\s*engineer|architect|designer|'
    r'developer|programmer|analyst|consultant|advisor|adviser|specialist|'
    r'coordinator|co-?ordinator|supervisor|superintendent|administrator|'
    r'accountant|auditor|cashier|clerk|secretary|assistant|associate|'
    r'representative|agent|broker|dealer|distributor|contractor|'
    r'technician|operator|surveyor|estimator|planner|'
    r'doctor|dr|physician|surgeon|dentist|consultant\s*physician|'
    r'advocate|lawyer|attorney|solicitor|notary|'
    r'chartered\s*accountant|company\s*secretary|cost\s*accountant|'
    r'professor|lecturer|teacher|trainer|coach|principal\s*scientist|'
    r'scientist|researcher|technologist|pharmacist|nutritionist|'
    r'sales\s*(head|manager|executive|officer|engineer)|'
    r'marketing\s*(head|manager|executive|officer)|'
    r'operations?\s*(head|manager|executive)|'
    r'hr\s*(head|manager|executive)|'
    r'finance\s*(head|manager|controller)|'
    r'purchase\s*(head|manager|executive)|'
    r'production\s*(head|manager|incharge)|'
    r'store\s*(manager|incharge)|in-?charge|team\s*lead|tech\s*lead|lead'
    r')\b',
    caseSensitive: false,
  );

  static void _extractDesignation(_Ctx ctx) {
    for (var i = 0; i < ctx.lines.length; i++) {
      if (ctx.isConsumed(i, _Use.address)) continue;
      final text = ctx.residual(i);
      if (text.isEmpty) continue;
      // A whole address or a long sentence isn't a job title.
      if (text.length > 60) continue;
      final match = _designationRe.firstMatch(text);
      if (match == null) continue;

      // A line can hold both — "Rahul Mehta, Sales Manager". Keep only the part
      // that carries the title so the name half survives for the name pass.
      final split = _splitOnSeparator(text, match.start);
      final title = split.matched.trim();
      if (title.isEmpty) continue;
      // A legal-entity suffix means this is the company line, not a title.
      // Only *entity* words veto here — plain industry words must not, or
      // "Senior Consultant" and "Product Design Lead" would be thrown away.
      if (_legalEntityRe.hasMatch(title)) continue;

      ctx.designation = _titleCase(title);
      ctx.designationLine = i;
      if (split.other.trim().isNotEmpty) {
        // Leave the other half available to the name/company passes.
        ctx.setResidual(i, split.other.trim());
      } else {
        ctx.consume(i, _Use.designation);
      }
      return;
    }
  }

  /// Splits `text` around the separator nearest to [at], returning the half that
  /// contains [at] and the half that does not.
  ///
  /// `:` counts as a separator because cards label the title as often as they
  /// print it plain — "Prop: Mr. Suresh Gupta" must yield both halves.
  static _Split _splitOnSeparator(String text, int at) {
    final separators = RegExp(r'\s*[,|/·•\-–:]\s*');
    final matches = separators.allMatches(text).toList();
    if (matches.isEmpty) return _Split(text, '');
    // Nearest separator before the hit, and nearest after.
    final before = matches.where((m) => m.end <= at).toList();
    final after = matches.where((m) => m.start > at).toList();
    final start = before.isEmpty ? 0 : before.last.end;
    final end = after.isEmpty ? text.length : after.first.start;
    final matched = text.substring(start, end);
    final head = text.substring(0, before.isEmpty ? 0 : before.last.start);
    final tail = after.isEmpty ? '' : text.substring(after.first.end);
    final other = '$head $tail'.trim();
    return _Split(matched, other);
  }

  // ───────────────────────────── company ───────────────────────────────────

  /// Words that mark a *registered entity*. Narrower than [_companySuffixRe] on
  /// purpose: these can never appear in a job title, so they are safe to use as
  /// a veto when deciding what a line is.
  static final RegExp _legalEntityRe = RegExp(
    r'\b(pvt\.?\s*ltd|private\s*limited|p\.?\s?ltd|ltd\.?|limited|llp|llc|'
    r'inc\.?|incorporated|corp\.?|corporation|co\.|gmbh|plc|sarl|'
    r'pte\.?\s*ltd|sdn\.?\s*bhd|fzc|fze|fz-?llc|w\.?l\.?l\.?)\b',
    caseSensitive: false,
  );

  static final RegExp _companySuffixRe = RegExp(
    r'\b('
    r'pvt\.?\s*ltd|private\s*limited|p\.?\s?ltd|ltd\.?|limited|llp|llc|'
    r'inc\.?|incorporated|corp\.?|corporation|co\.|company|gmbh|ag|bv|nv|plc|'
    r'sarl|s\.a\.?|pte\.?\s*ltd|sdn\.?\s*bhd|fzc|fze|fz-?llc|w\.?l\.?l\.?|'
    r'group|holdings?|enterprises?|entp|industries|industrial|technologies|'
    r'technology|infotech|softwares?|systems?|solutions?|services?|consultancy|'
    r'consultants?|associates?|traders?|trading|exports?|imports?|impex|'
    r'agencies|agency|ventures?|partners?|labs?|laboratories|foundation|trust|'
    r'society|works|manufacturers?|manufacturing|engineers?|engineering|'
    r'constructions?|infra(?:structure)?|builders?|developers?|realty|estates?|'
    r'properties|motors?|automobiles?|auto|pharma|pharmaceuticals?|healthcare|'
    r'chemicals?|textiles?|fabrics|garments|apparels?|steel|metals?|alloys|'
    r'electricals?|electronics?|instruments?|equipments?|machinery|tools|'
    r'packaging|plastics|polymers|papers?|prints?|printers?|printing|graphics|'
    r'logistics|transport|carriers|couriers|shipping|freight|forwarders|'
    r'hospitality|hotels?|resorts?|restaurants?|caterers?|foods?|beverages|'
    r'clinic|hospital|diagnostics|labs|academy|institute|school|college|'
    r'university|media|marketing|advertising|communications?|interiors?|'
    r'architects?|designs?|studios?|finance|financial|fintech|insurance|'
    r'capital|investments?|securities|bank|brokers?|distributors?|'
    r'suppliers?|stores?|mart|bazaar|retail|wholesale|corporation'
    r')\b',
    caseSensitive: false,
  );

  static void _extractCompany(_Ctx ctx) {
    // The strongest possible signal: a line that *is* the website's domain.
    final domainRoot = _domainRoot(ctx.website.isNotEmpty
        ? ctx.website
        : (ctx.email.contains('@') ? ctx.email.split('@').last : ''));

    _Scored? best;
    for (var i = 0; i < ctx.lines.length; i++) {
      if (ctx.isConsumed(i, _Use.address)) continue;
      if (ctx.isConsumed(i, _Use.designation)) continue;
      final text = ctx.residual(i);
      if (text.trim().length < 3) continue;
      if (!RegExp(r'[A-Za-z]{2}').hasMatch(text)) continue;
      if (i == ctx.designationLine && ctx.designation.isNotEmpty) continue;

      var score = 0.0;
      if (_companySuffixRe.hasMatch(text)) score += 6;
      if (domainRoot.isNotEmpty && _squash(text).contains(domainRoot)) {
        score += 8;
      }
      // A tagline ("Your partner in growth") isn't a company name.
      final words = text.split(' ').where((w) => w.isNotEmpty).length;
      if (words > 7) score -= 4;
      if (text.endsWith('.') && words > 4) score -= 2;
      // ALL CAPS is the house style for company names on most cards.
      final letters = text.replaceAll(RegExp(r'[^A-Za-z]'), '');
      if (letters.length > 3 && letters == letters.toUpperCase()) score += 1.5;
      // Bigger type near the top of the card.
      score += ctx.relativeSize(i) * 2;
      if (i <= 2) score += 0.5;
      // Never let a job title become the company.
      if (_designationRe.hasMatch(text) && !_companySuffixRe.hasMatch(text)) {
        score -= 5;
      }
      if (score <= 0) continue;
      if (best == null || score > best.score) best = _Scored(i, score, text);
    }

    if (best != null && best.score >= 2) {
      ctx.company = _tidyCompany(best.text);
      ctx.companyLine = best.index;
      ctx.consume(best.index, _Use.company);
      return;
    }
    // Nothing on the card looked like a company — rebuild it from the domain,
    // which is right far more often than it is wrong.
    if (domainRoot.isNotEmpty && !_publicMailDomains.contains(domainRoot)) {
      ctx.company = _titleCase(domainRoot);
    }
  }

  /// The registrable label of a host: `www.acme-steel.co.in` → `acmesteel`.
  static String _domainRoot(String hostOrDomain) {
    if (hostOrDomain.isEmpty) return '';
    var host = hostOrDomain
        .toLowerCase()
        .replaceFirst(RegExp(r'^https?://'), '')
        .split('/')
        .first
        .replaceFirst(RegExp(r'^www\.'), '');
    final labels = host.split('.').where((l) => l.isNotEmpty).toList();
    if (labels.isEmpty) return '';
    // Strip the public suffix, allowing for two-part ones like `co.in`.
    var root = labels.first;
    if (labels.length > 2 &&
        const {'co', 'com', 'net', 'org', 'gov', 'ac', 'edu'}
            .contains(labels[labels.length - 2])) {
      root = labels[labels.length - 3];
    }
    if (_publicMailDomains.contains(root)) return root;
    return root.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static String _tidyCompany(String text) {
    var out = text.trim().replaceAll(RegExp(r'[\s,;|]+$'), '');
    // A screaming all-caps name reads better title-cased, but a name with
    // deliberate mixed case (e.g. "TechnoVent") must be left alone.
    final letters = out.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (letters.length > 4 && letters == letters.toUpperCase()) {
      out = _titleCase(out);
    }
    return out;
  }

  // ────────────────────────────── name ─────────────────────────────────────

  static final RegExp _honorificRe = RegExp(
    r'^\s*(mr|mrs|ms|miss|mstr|dr|prof|er|ar|ca|cs|cma|adv|advocate|shri|sri|'
    r'smt|kum|capt|col|maj|lt|gen|rev|fr|sh|hon)\b\.?\s+',
    caseSensitive: false,
  );

  static void _extractName(_Ctx ctx) {
    final emailTokens = _emailNameTokens(ctx.email);

    _Scored? best;
    for (var i = 0; i < ctx.lines.length; i++) {
      if (ctx.isConsumed(i, _Use.address)) continue;
      if (ctx.isConsumed(i, _Use.company)) continue;
      if (ctx.isConsumed(i, _Use.designation)) continue;

      var text = ctx.residual(i).trim();
      if (text.isEmpty) continue;

      final hadHonorific = _honorificRe.hasMatch(text);
      if (hadHonorific) text = text.replaceFirst(_honorificRe, '').trim();
      if (text.length < 3) continue;

      // Hard disqualifiers — a name never carries these.
      if (RegExp(r'\d').hasMatch(text)) continue;
      if (text.contains('@')) continue;
      if (_companySuffixRe.hasMatch(text)) continue;
      if (_strongAddressRe.hasMatch(text)) continue;
      final words = text
          .split(RegExp(r'\s+'))
          .where((w) => w.replaceAll(RegExp(r'[^A-Za-z]'), '').isNotEmpty)
          .toList();
      if (words.isEmpty || words.length > 5) continue;
      // Names are letters, spaces, dots (initials), apostrophes and hyphens.
      if (!RegExp(r"^[A-Za-z][A-Za-z.'\-\s]*$").hasMatch(text)) continue;

      var score = 0.0;
      if (hadHonorific) score += 6;
      if (words.length >= 2 && words.length <= 3) score += 3;
      if (words.length == 1) score += 0.5;
      if (words.length >= 4) score += 0.5;
      // Directly above or below the designation is where the name lives.
      if (ctx.designationLine != null) {
        if (i == ctx.designationLine! - 1) score += 4;
        if (i == ctx.designationLine! + 1) score += 3;
      }
      // The largest text on the card is usually the person (or the company,
      // which has already been consumed by now).
      score += ctx.relativeSize(i) * 3;
      if (i <= 3) score += 0.5;
      // Agreement with the email's local part is close to proof.
      final overlap = words
          .map((w) => w.toLowerCase().replaceAll(RegExp(r'[^a-z]'), ''))
          .where((w) => w.length > 2 && emailTokens.contains(w))
          .length;
      score += overlap * 4;
      // Title Case is the norm; all-lowercase is usually a tagline fragment.
      final titleCased = words.every((w) =>
          w.isNotEmpty && w[0] == w[0].toUpperCase());
      if (titleCased) score += 1.5;
      if (_designationRe.hasMatch(text)) score -= 4;

      if (score <= 0) continue;
      if (best == null || score > best.score) best = _Scored(i, score, text);
    }

    if (best != null) {
      ctx.consume(best.index, _Use.name);
      _assignName(ctx, best.text);
      return;
    }

    // Last resort: rebuild the name from the mailbox — `rahul.mehta@…` is a
    // person, `info@…` is not.
    if (emailTokens.isNotEmpty) {
      final local = ctx.email.split('@').first;
      if (!_genericLocals.contains(local.toLowerCase())) {
        final rebuilt = emailTokens
            .where((t) => t.length > 1)
            .map(_titleCase)
            .join(' ');
        if (rebuilt.trim().isNotEmpty) _assignName(ctx, rebuilt);
      }
    }
  }

  /// The word-ish pieces of an email's local part: `rahul.mehta91` → {rahul,
  /// mehta}. Used both to score name candidates and to rebuild a missing name.
  static Set<String> _emailNameTokens(String email) {
    if (!email.contains('@')) return const {};
    final local = email.split('@').first.toLowerCase();
    if (_genericLocals.contains(local)) return const {};
    return local
        .split(RegExp(r'[._\-+0-9]+'))
        .map((t) => t.trim())
        .where((t) => t.length > 1)
        .toSet();
  }

  static void _assignName(_Ctx ctx, String raw) {
    var text = raw.replaceFirst(_honorificRe, '').trim();
    text = text.replaceAll(RegExp(r'[\s,.]+$'), '').trim();
    if (text.isEmpty) return;
    final parts = text.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final cased = parts.map(_titleCase).toList();
    ctx.firstName = cased.first;
    // Everything after the first word is the surname — safer than guessing at
    // middle names, and the CRM shows them joined anyway.
    ctx.lastName = cased.length > 1 ? cased.sublist(1).join(' ') : '';
  }

  // ────────────────────────────── helpers ──────────────────────────────────

  /// Title-cases a phrase while leaving intentional mixed case alone and
  /// keeping short connectors ("and", "of") lowercase.
  static String _titleCase(String text) {
    const lowerWords = {'and', 'of', 'the', 'for', 'in', 'at', 'on', 'to', 'de'};
    final words = text.trim().split(RegExp(r'\s+'));
    return words
        .asMap()
        .entries
        .map((entry) {
          final word = entry.value;
          if (word.isEmpty) return word;
          final letters = word.replaceAll(RegExp(r'[^A-Za-z]'), '');
          // Preserve deliberate casing like "McKinsey" or "eBay".
          final isFlatCase = letters.isEmpty ||
              letters == letters.toUpperCase() ||
              letters == letters.toLowerCase();
          if (!isFlatCase) return word;
          final lower = word.toLowerCase();
          if (entry.key > 0 && lowerWords.contains(lower)) return lower;
          // Keep known acronyms shouting.
          if (letters.length <= 3 &&
              letters == letters.toUpperCase() &&
              letters.length > 1) {
            return word;
          }
          return lower[0].toUpperCase() + lower.substring(1);
        })
        .join(' ');
  }

  static String _squash(String text) =>
      text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

// ─────────────────────────── internal types ────────────────────────────────

enum _Use { contact, address, designation, company, name }

enum _PhoneKind { mobile, landline, tollFree, fax, unknown }

class _Phone {
  final String value;
  final _PhoneKind kind;
  final String key;
  const _Phone(this.value, this.kind, this.key);
}

class _Gazetteer {
  final String canonical;
  final int start;
  final int end;
  const _Gazetteer(this.canonical, this.start, this.end);
}

class _Scored {
  final int index;
  final double score;
  final String text;
  const _Scored(this.index, this.score, this.text);
}

class _Split {
  /// The half containing the match.
  final String matched;

  /// The remainder of the line.
  final String other;
  const _Split(this.matched, this.other);
}

/// Mutable working state for one parse: the prepared lines, what each extractor
/// has already claimed, and the fields collected so far.
class _Ctx {
  final List<OcrLine> lines;

  /// Per-line text with the spans consumed by emails, URLs and phone numbers
  /// blanked out. Later extractors read this instead of the raw line, so
  /// `"Rahul Mehta  |  +91 98200 11111"` can still yield a name.
  final List<String> _residual;

  final List<Set<_Use>> _uses;
  final List<List<_Span>> _emailSpans;
  final List<List<_Span>> _urlSpans;
  final double _maxHeight;

  String firstName = '';
  String lastName = '';
  String phone = '';
  String alternatePhone = '';
  String email = '';
  List<String> allEmails = const [];
  String company = '';
  String designation = '';
  String website = '';
  String address = '';
  String city = '';
  String state = '';
  String pincode = '';
  String country = '';

  int? designationLine;
  int? companyLine;

  _Ctx(this.lines)
      : _residual = lines.map((l) => l.text).toList(),
        _uses = List.generate(lines.length, (_) => <_Use>{}),
        _emailSpans = List.generate(lines.length, (_) => <_Span>[]),
        _urlSpans = List.generate(lines.length, (_) => <_Span>[]),
        _maxHeight = lines.fold<double>(
            0, (max, l) => l.height > max ? l.height : max);

  String residual(int index) => _residual[index].trim();

  void setResidual(int index, String value) => _residual[index] = value;

  void consume(int index, _Use use) => _uses[index].add(use);

  bool isConsumed(int index, _Use use) => _uses[index].contains(use);

  void markEmailSpan(int index, int start, int end) {
    _emailSpans[index].add(_Span(start, end));
    _blank(index, start, end);
  }

  void markUrlSpan(int index, int start, int end) {
    _urlSpans[index].add(_Span(start, end));
    _blank(index, start, end);
  }

  void markPhoneSpan(int index, int start, int end) => _blank(index, start, end);

  /// Blanks a span in the residual text without shifting any offsets, so spans
  /// found later still line up with the original line.
  void _blank(int index, int start, int end) {
    final text = _residual[index];
    if (start < 0 || end > text.length || start >= end) return;
    _residual[index] =
        text.substring(0, start) + ' ' * (end - start) + text.substring(end);
  }

  bool overlapsEmail(int index, int start, int end) =>
      _emailSpans[index].any((s) => s.overlaps(start, end));

  bool overlapsUrl(int index, int start, int end) =>
      _urlSpans[index].any((s) => s.overlaps(start, end));

  /// This line's text size as a fraction of the biggest line on the card —
  /// `0` when the engine reported no geometry.
  double relativeSize(int index) {
    if (_maxHeight <= 0) return 0;
    return (lines[index].height / _maxHeight).clamp(0, 1);
  }

  BusinessCardData build() {
    return BusinessCardData(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      alternatePhone: alternatePhone,
      email: email,
      company: company,
      designation: designation,
      website: website,
      address: address,
      city: city,
      state: state,
      pincode: pincode,
      country: country,
      rawLines: lines.map((l) => l.text).toList(growable: false),
    );
  }
}

class _Span {
  final int start;
  final int end;
  const _Span(this.start, this.end);

  bool overlaps(int otherStart, int otherEnd) =>
      otherStart < end && start < otherEnd;
}
