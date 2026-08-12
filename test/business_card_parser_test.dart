import 'package:crm_app/features/Leads/data/business_card_parser.dart';
import 'package:crm_app/features/Leads/model/business_card_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds OCR lines with plausible geometry: lines stack top to bottom, and
/// [big] marks the oversized text (the name or the company) so the layout rules
/// have something to work with — exactly what ML Kit reports off a real photo.
List<OcrLine> layout(List<String> lines, {Set<int> big = const {}}) {
  final out = <OcrLine>[];
  var top = 0.0;
  for (var i = 0; i < lines.length; i++) {
    final height = big.contains(i) ? 42.0 : 22.0;
    out.add(OcrLine(
      text: lines[i],
      left: 40,
      top: top,
      width: lines[i].length * 12.0,
      height: height,
    ));
    top += height + 12;
  }
  return out;
}

void main() {
  group('Indian corporate card', () {
    late BusinessCardData card;

    setUp(() {
      card = BusinessCardParser.parse(layout([
        'SHREE BALAJI INDUSTRIES PVT. LTD.',
        'Rajesh Kumar Sharma',
        'Sales Manager',
        'Mob: +91 98765 43210',
        'Tel: 022 2856 4477 | Fax: 022 2856 4478',
        'Email: rajesh.sharma@shreebalaji.co.in',
        'www.shreebalaji.co.in',
        'Plot No. 42, MIDC Industrial Area, Andheri East,',
        'Mumbai - 400093, Maharashtra, India',
      ], big: {0, 1}));
    });

    test('reads the person', () {
      expect(card.firstName, 'Rajesh');
      expect(card.lastName, 'Kumar Sharma');
    });

    test('prefers the mobile over the landline and never the fax', () {
      expect(card.phone, '+91 9876543210');
      expect(card.alternatePhone, isNot(contains('28564478')));
    });

    test('reads email, website and company', () {
      expect(card.email, 'rajesh.sharma@shreebalaji.co.in');
      expect(card.website, 'www.shreebalaji.co.in');
      expect(card.company, contains('Balaji'));
      expect(card.designation, 'Sales Manager');
    });

    test('splits the address into its CRM fields', () {
      expect(card.pincode, '400093');
      expect(card.state, 'Maharashtra');
      expect(card.city, 'Mumbai');
      expect(card.country, 'India');
      expect(card.address, contains('MIDC'));
      expect(card.address, isNot(contains('400093')));
      expect(card.address, isNot(contains('Maharashtra')));
    });
  });

  group('minimal western card', () {
    late BusinessCardData card;

    setUp(() {
      card = BusinessCardParser.parse(layout([
        'Sarah Mitchell',
        'Product Design Lead',
        'Northbridge Studio',
        'sarah@northbridge.design',
        '+44 7700 900123',
      ], big: {0}));
    });

    test('name and title', () {
      expect(card.firstName, 'Sarah');
      expect(card.lastName, 'Mitchell');
      expect(card.designation, contains('Lead'));
    });

    test('company and contact', () {
      expect(card.company, 'Northbridge Studio');
      expect(card.email, 'sarah@northbridge.design');
      expect(card.phone, '+44 7700900123');
    });

    test('leaves address fields empty rather than inventing them', () {
      expect(card.address, isEmpty);
      expect(card.city, isEmpty);
      expect(card.pincode, isEmpty);
    });
  });

  group('label-heavy card with T/M/F shorthand', () {
    late BusinessCardData card;

    setUp(() {
      card = BusinessCardParser.parse(layout([
        'ANITA DESAI',
        'Chief Financial Officer',
        'Vertex Technologies Limited',
        'T +91 79 4004 1122',
        'M +91 99999 88888',
        'F +91 79 4004 1123',
        'E anita.desai@vertextech.com',
        'W vertextech.com',
        '5th Floor, Titanium Square, Thaltej Road,',
        'Ahmedabad 380059, Gujarat',
      ], big: {0}));
    });

    test('M wins over T and F is discarded', () {
      expect(card.phone, '+91 9999988888');
      expect(card.alternatePhone, '+91 7940041122');
    });

    test('single-letter E and W labels are not mistaken for content', () {
      expect(card.email, 'anita.desai@vertextech.com');
      expect(card.website, 'vertextech.com');
    });

    test('shouty name is title-cased', () {
      expect(card.firstName, 'Anita');
      expect(card.lastName, 'Desai');
    });

    test('locality', () {
      expect(card.city, 'Ahmedabad');
      expect(card.state, 'Gujarat');
      expect(card.pincode, '380059');
    });
  });

  group('two numbers on one line', () {
    test('splits on the slash and keeps both', () {
      final card = BusinessCardParser.parse(layout([
        'Vikram Singh',
        'Proprietor',
        'Singh Trading Co.',
        'Mob: 9820011111 / 9820022222',
        'vikram@singhtrading.in',
      ]));
      expect(card.phone, '9820011111');
      expect(card.alternatePhone, '9820022222');
    });
  });

  group('noisy trader card', () {
    late BusinessCardData card;

    setUp(() {
      card = BusinessCardParser.parse(layout([
        'JAI MATA DI ENTERPRISES',
        'Dealers in Steel & Hardware',
        'GSTIN: 27AABCU9603R1ZM',
        'Prop: Mr. Suresh Gupta',
        'Cell: 98200 12345',
        'Shop No. 7, Lohar Chawl, Kalbadevi Road,',
        'Mumbai - 400002',
        'Email: jaimatadi.ent@gmail.com',
      ], big: {0}));
    });

    test('the GSTIN is never read as a phone number', () {
      expect(card.phone, '9820012345');
      expect(card.alternatePhone, isEmpty);
    });

    test('the honorific is stripped from the name', () {
      expect(card.firstName, 'Suresh');
      expect(card.lastName, 'Gupta');
    });

    test('a public mail domain does not become the company', () {
      expect(card.company.toLowerCase(), isNot(contains('gmail')));
      expect(card.company, contains('Enterprises'));
    });

    test('address survives the shop-number prefix', () {
      expect(card.address, contains('Lohar Chawl'));
      expect(card.city, 'Mumbai');
      expect(card.pincode, '400002');
    });
  });

  group('name and title on one line', () {
    test('splits the line and keeps both halves', () {
      final card = BusinessCardParser.parse(layout([
        'Meridian Consulting LLP',
        'Priya Nair, Senior Consultant',
        'priya.nair@meridian-consulting.com',
        '+91 80 4123 9000',
      ], big: {0}));
      expect(card.firstName, 'Priya');
      expect(card.lastName, 'Nair');
      expect(card.designation, 'Senior Consultant');
      expect(card.company, contains('Meridian'));
    });
  });

  group('OCR damage', () {
    test('repairs a mangled mail domain and spaced-out address', () {
      final card = BusinessCardParser.parse(layout([
        'Karan Mehta',
        'Director',
        'karan.mehta @ gmai1.corn',
        'Mobile : 0 98111 22333',
      ]));
      expect(card.email, 'karan.mehta@gmail.com');
      expect(card.phone, '9811122333');
    });

    test('rejoins an email split across two lines', () {
      final card = BusinessCardParser.parse(layout([
        'Global Exports Pvt Ltd',
        'sales@',
        'globalexports.co.in',
        '+91 44 2811 5566',
      ]));
      expect(card.email, 'sales@globalexports.co.in');
    });
  });

  group('name recovery', () {
    test('rebuilds a missing name from the mailbox', () {
      final card = BusinessCardParser.parse(layout([
        'ACME LOGISTICS PVT LTD',
        '+91 22 6677 8899',
        'deepak.verma@acmelogistics.com',
      ]));
      expect(card.firstName, 'Deepak');
      expect(card.lastName, 'Verma');
    });

    test('does not invent a name from info@', () {
      final card = BusinessCardParser.parse(layout([
        'ACME LOGISTICS PVT LTD',
        '+91 22 6677 8899',
        'info@acmelogistics.com',
      ]));
      expect(card.firstName, isEmpty);
      expect(card.email, 'info@acmelogistics.com');
    });

    test('prefers a personal mailbox when the card carries both', () {
      final card = BusinessCardParser.parse(layout([
        'Nova Systems',
        'Amit Roy',
        'Manager',
        'info@novasystems.in',
        'amit.roy@novasystems.in',
      ]));
      expect(card.email, 'amit.roy@novasystems.in');
    });
  });

  group('front and back of the same card', () {
    test('merges both sides into one lead', () {
      final front = layout([
        'Hexa Interiors',
        'Rohit Malhotra',
        'Design Head',
        '+91 97000 45678',
      ], big: {1});
      final back = [
        for (final line in layout([
          'B-14, Sector 63, Noida - 201301',
          'Uttar Pradesh',
          'rohit@hexainteriors.com',
        ]))
          OcrLine(
            text: line.text,
            left: line.left,
            top: line.top,
            width: line.width,
            height: line.height,
            page: 1,
          ),
      ];
      final card = BusinessCardParser.parse([...front, ...back]);

      expect(card.firstName, 'Rohit');
      expect(card.phone, '+91 9700045678');
      expect(card.email, 'rohit@hexainteriors.com');
      expect(card.city, 'Noida');
      expect(card.state, 'Uttar Pradesh');
      expect(card.pincode, '201301');
    });
  });

  group('US card', () {
    test('reads the state from the code that precedes the ZIP', () {
      final card = BusinessCardParser.parse(layout([
        'Brightline Analytics Inc.',
        'Daniel Foster',
        'VP, Business Development',
        'daniel.foster@brightline.io',
        'Office: (415) 555-0182',
        'Cell: (415) 555-0199',
        '1200 Market Street, Suite 400',
        'San Francisco, CA 94103',
      ], big: {1}));

      expect(card.firstName, 'Daniel');
      expect(card.lastName, 'Foster');
      expect(card.city, 'San Francisco');
      expect(card.state, 'California');
      expect(card.pincode, '94103');
      expect(card.address, contains('Market Street'));
      expect(card.phone, '4155550199'); // the cell, not the office line
      expect(card.alternatePhone, '4155550182');
    });
  });

  group('WhatsApp-labelled number', () {
    test('is treated as the mobile', () {
      final card = BusinessCardParser.parse(layout([
        'Kiran Rao',
        'Boutique Owner',
        'Landline: 080 2345 6789',
        'WhatsApp: +91 90000 11223',
      ]));
      expect(card.phone, '+91 9000011223');
      expect(card.alternatePhone, '08023456789');
    });
  });

  group('degenerate input', () {
    test('empty input yields an empty result instead of throwing', () {
      final card = BusinessCardParser.parse(const []);
      expect(card.isEmpty, isTrue);
      expect(card.rawLines, isEmpty);
    });

    test('a photo of a wall yields nothing but keeps the raw text', () {
      final card = BusinessCardParser.parse(layout(['EXIT', 'FIRE HOSE']));
      expect(card.phone, isEmpty);
      expect(card.email, isEmpty);
      expect(card.rawLines, hasLength(2));
    });

    test('a date is not read as a phone number', () {
      final card = BusinessCardParser.parse(layout([
        'Certified since 20180115',
        'Anil Joshi',
      ]));
      expect(card.phone, isEmpty);
    });
  });
}
