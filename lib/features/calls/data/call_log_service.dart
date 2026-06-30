import 'dart:io';

import 'package:call_log/call_log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../model/call_record.dart';
import '../util/phone_utils.dart';

/// One raw call read from the device call log, normalized into the app's own
/// shape so the rest of the feature never touches the `call_log` plugin types.
class DeviceCallEntry {
  final String number;
  final String? name;
  final AppCallType type;
  final int durationSeconds;
  final DateTime timestamp;

  const DeviceCallEntry({
    required this.number,
    this.name,
    required this.type,
    required this.durationSeconds,
    required this.timestamp,
  });
}

/// Reads the device call history and manages the runtime permission.
///
/// Everything here is **Android-only**: iOS gives no API to read call history,
/// so every method no-ops (returns `false` / empty) on other platforms.
class CallLogService {
  /// Whether reading the call log is even possible on this platform.
  bool get isSupported => Platform.isAndroid;

  /// Current grant status of the call-log permission, without prompting.
  Future<bool> get isGranted async {
    if (!isSupported) return false;
    return Permission.phone.isGranted;
  }

  /// Returns whether the call-log permission is granted, optionally prompting
  /// the user for it once. On non-Android platforms this is always `false`.
  ///
  /// `READ_CALL_LOG` belongs to permission_handler's `phone` group, and since
  /// that's the only phone-group permission declared in the manifest, the
  /// system dialog asks specifically for call-log access.
  Future<bool> ensurePermission({bool request = false}) async {
    if (!isSupported) return false;
    var status = await Permission.phone.status;
    if (status.isGranted) return true;
    if (request && (status.isDenied || status.isRestricted)) {
      status = await Permission.phone.request();
    }
    return status.isGranted;
  }

  /// Reads call-log entries with a [timestamp] at or after [since]. Returns an
  /// empty list when unsupported / not granted so callers don't need to guard.
  Future<List<DeviceCallEntry>> query({required DateTime since}) async {
    if (!await ensurePermission()) return const [];

    final Iterable<CallLogEntry> entries = await CallLog.query(
      dateFrom: since.millisecondsSinceEpoch,
    );

    final result = <DeviceCallEntry>[];
    for (final e in entries) {
      final number = e.number ?? e.formattedNumber;
      if (number == null || number.trim().isEmpty) continue;
      result.add(
        DeviceCallEntry(
          number: number,
          name: e.name,
          type: _mapType(e.callType),
          durationSeconds: e.duration ?? 0,
          timestamp:
              DateTime.fromMillisecondsSinceEpoch(e.timestamp ?? 0),
        ),
      );
    }
    return result;
  }

  /// Returns the single most recent call-log entry whose number matches
  /// [number] (compared loosely via [PhoneUtils]) with a timestamp at/after
  /// [since], or null if there's no such call. Used to capture just the latest
  /// call for the number the user dialed.
  Future<DeviceCallEntry?> latestForNumber(
    String number, {
    required DateTime since,
  }) async {
    final entries = await query(since: since);
    DeviceCallEntry? latest;
    for (final e in entries) {
      if (!PhoneUtils.sameNumber(e.number, number)) continue;
      if (latest == null || e.timestamp.isAfter(latest.timestamp)) {
        latest = e;
      }
    }
    return latest;
  }

  AppCallType _mapType(CallType? type) {
    switch (type) {
      case CallType.incoming:
      case CallType.wifiIncoming:
        return AppCallType.incoming;
      case CallType.outgoing:
      case CallType.wifiOutgoing:
        return AppCallType.outgoing;
      case CallType.missed:
        return AppCallType.missed;
      case CallType.rejected:
        return AppCallType.rejected;
      case CallType.blocked:
        return AppCallType.blocked;
      default:
        return AppCallType.unknown;
    }
  }
}

final callLogServiceProvider = Provider<CallLogService>((ref) {
  return CallLogService();
});
