import 'package:crm_app/features/calls/model/call_record.dart';
import 'package:crm_app/features/calls/widget/lead_call_logs_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A fixed Wednesday afternoon to anchor every relative assertion.
  final now = DateTime(2026, 8, 5, 14, 30);

  group('formatCallDate', () {
    test('the two most recent days read as Today / Yesterday', () {
      expect(
        CallLogsList.formatCallDate(DateTime(2026, 8, 5, 9, 15), now: now),
        'Today',
      );
      expect(
        CallLogsList.formatCallDate(DateTime(2026, 8, 4, 23, 59), now: now),
        'Yesterday',
      );
    });

    test('Today is by calendar day, not by elapsed hours', () {
      // 00:05 today is under 24h ago but is still "Today"…
      expect(
        CallLogsList.formatCallDate(DateTime(2026, 8, 5, 0, 5), now: now),
        'Today',
      );
      // …and 23:00 yesterday is under 24h ago yet must not be.
      expect(
        CallLogsList.formatCallDate(DateTime(2026, 8, 4, 23, 0), now: now),
        'Yesterday',
      );
    });

    test('the past week carries the weekday', () {
      expect(
        CallLogsList.formatCallDate(DateTime(2026, 8, 3, 10), now: now),
        'Mon, 3 Aug',
      );
      expect(
        CallLogsList.formatCallDate(DateTime(2026, 7, 31, 10), now: now),
        'Fri, 31 Jul',
      );
    });

    test('older dates in the current year omit the year', () {
      expect(
        CallLogsList.formatCallDate(DateTime(2026, 3, 18, 10), now: now),
        '18 Mar',
      );
    });

    test('a different year is spelled out', () {
      expect(
        CallLogsList.formatCallDate(DateTime(2025, 12, 24, 10), now: now),
        '24 Dec 2025',
      );
    });

    test('the 7-day boundary falls back to the plain date', () {
      // Exactly 7 days back is no longer "this week".
      expect(
        CallLogsList.formatCallDate(DateTime(2026, 7, 29, 10), now: now),
        '29 Jul',
      );
      expect(
        CallLogsList.formatCallDate(DateTime(2026, 7, 30, 10), now: now),
        'Thu, 30 Jul',
      );
    });
  });

  group('formatCallTime', () {
    test('renders 12-hour time with a padded minute', () {
      expect(CallLogsList.formatCallTime(DateTime(2026, 8, 5, 14, 45)),
          '2:45 PM');
      expect(CallLogsList.formatCallTime(DateTime(2026, 8, 5, 9, 5)),
          '9:05 AM');
    });

    test('midnight and noon are 12, not 0', () {
      expect(CallLogsList.formatCallTime(DateTime(2026, 8, 5, 0, 0)),
          '12:00 AM');
      expect(CallLogsList.formatCallTime(DateTime(2026, 8, 5, 12, 0)),
          '12:00 PM');
      expect(CallLogsList.formatCallTime(DateTime(2026, 8, 5, 0, 30)),
          '12:30 AM');
    });

    test('late evening stays PM', () {
      expect(CallLogsList.formatCallTime(DateTime(2026, 8, 5, 23, 59)),
          '11:59 PM');
    });
  });

  group('timeAgo', () {
    test('scales from minutes through years', () {
      expect(
        CallLogsList.timeAgo(now.subtract(const Duration(seconds: 20)),
            now: now),
        'Just now',
      );
      expect(
        CallLogsList.timeAgo(now.subtract(const Duration(minutes: 45)),
            now: now),
        '45m ago',
      );
      expect(
        CallLogsList.timeAgo(now.subtract(const Duration(hours: 5)), now: now),
        '5h ago',
      );
      expect(
        CallLogsList.timeAgo(now.subtract(const Duration(days: 3)), now: now),
        '3d ago',
      );
      expect(
        CallLogsList.timeAgo(now.subtract(const Duration(days: 14)), now: now),
        '2w ago',
      );
      expect(
        CallLogsList.timeAgo(now.subtract(const Duration(days: 90)), now: now),
        '3mo ago',
      );
      expect(
        CallLogsList.timeAgo(now.subtract(const Duration(days: 400)), now: now),
        '1y ago',
      );
    });

    test('a future timestamp from clock skew reads as Just now', () {
      expect(
        CallLogsList.timeAgo(now.add(const Duration(minutes: 3)), now: now),
        'Just now',
      );
    });
  });

  group('LeadCallLog.calledAt', () {
    test('a UTC called_at parses as UTC and converts to local for display', () {
      final log = LeadCallLog.fromJson(const {
        'id': 1,
        'called_at': '2026-08-05T09:00:00.000000Z',
      });

      expect(log.calledAt, isNotNull);
      expect(log.calledAt!.isUtc, isTrue);

      // The widget formats the local conversion — that is what makes the shown
      // clock time match the user's own timezone.
      final local = log.calledAt!.toLocal();
      expect(local.isUtc, isFalse);
      expect(
        local.difference(DateTime.utc(2026, 8, 5, 9)),
        Duration.zero,
      );
    });

    test('falls back to created_at when called_at is absent', () {
      final log = LeadCallLog.fromJson(const {
        'id': 2,
        'created_at': '2026-08-04T12:30:00.000000Z',
      });
      expect(log.calledAt, DateTime.utc(2026, 8, 4, 12, 30));
    });

    test('a missing timestamp is null rather than the epoch', () {
      expect(LeadCallLog.fromJson(const {'id': 3}).calledAt, isNull);
    });
  });
}
