import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';

/// Whether a newer build is live on Play and what the last update attempt did.
///
/// [updateRequired] is what gates the app: once Play reports a newer version,
/// it stays true until the update actually installs (which restarts the
/// process), so a user who backs out of Play's sheet lands right back on the
/// blocking screen instead of inside the CRM.
@immutable
class AppUpdateState {
  /// Play has a newer version than the one running — the update gate shows.
  final bool updateRequired;

  /// Play's own update UI is on screen (or the check that leads to it is in
  /// flight). Keeps the retry button from starting a second flow.
  final bool inProgress;

  /// Why the last attempt didn't finish — shown under the retry button. Null
  /// before the first attempt.
  final String? message;

  const AppUpdateState({
    this.updateRequired = false,
    this.inProgress = false,
    this.message,
  });

  AppUpdateState copyWith({
    bool? updateRequired,
    bool? inProgress,
    String? message,
  }) =>
      AppUpdateState(
        updateRequired: updateRequired ?? this.updateRequired,
        inProgress: inProgress ?? this.inProgress,
        message: message,
      );
}

/// Drives Google Play's in-app update flow.
///
/// The app is distributed through Play, so Play itself — not an API of ours —
/// is the source of truth for "is there a newer version". [check] asks it on
/// every launch and every resume; when an update exists it starts Play's
/// *immediate* flow, which downloads and installs inside the app and then
/// restarts it.
///
/// Nothing here works on a build that Play didn't install (debug runs,
/// sideloaded APKs, emulators without Play Store): `checkForUpdate` throws, and
/// every failure path deliberately leaves [AppUpdateState.updateRequired]
/// false. An update check must never be what keeps someone out of the CRM.
final appUpdateProvider =
    NotifierProvider<AppUpdateController, AppUpdateState>(
        AppUpdateController.new);

class AppUpdateController extends Notifier<AppUpdateState> {
  @override
  AppUpdateState build() => const AppUpdateState();

  /// Play Core is Android-only; everywhere else this is a no-op.
  bool get _supported => !kIsWeb && Platform.isAndroid;

  /// Asks Play whether a newer version exists and, if so, raises the gate and
  /// starts the update. Safe to call repeatedly — it ignores calls made while
  /// an update flow is already on screen.
  Future<void> check() async {
    if (!_supported || state.inProgress) return;

    final AppUpdateInfo info;
    try {
      info = await InAppUpdate.checkForUpdate();
    } catch (_) {
      // Not a Play-installed build, no Play Services, or the device is offline.
      // Let the user carry on.
      state = const AppUpdateState();
      return;
    }

    // `developerTriggeredUpdateInProgress` means an immediate update was
    // started and interrupted (the user swiped the app away mid-download).
    // Play requires it to be resumed on the next foreground.
    final resuming = info.updateAvailability ==
        UpdateAvailability.developerTriggeredUpdateInProgress;
    final available =
        info.updateAvailability == UpdateAvailability.updateAvailable;

    if (!resuming && !available) {
      state = const AppUpdateState();
      return;
    }

    // An update exists but Play won't run the immediate flow for it (an
    // unusual device/account state). Blocking would strand the user with no way
    // forward, so let them through — the next launch checks again.
    if (!resuming && !info.immediateUpdateAllowed) {
      state = const AppUpdateState();
      return;
    }

    state = state.copyWith(updateRequired: true);
    await start();
  }

  /// Opens Play's immediate-update sheet. On success the app is replaced and
  /// restarted by Play, so the state we set afterwards only matters when the
  /// user cancelled or something failed.
  Future<void> start() async {
    if (!_supported || state.inProgress) return;
    state = state.copyWith(updateRequired: true, inProgress: true);

    try {
      final result = await InAppUpdate.performImmediateUpdate();
      state = switch (result) {
        AppUpdateResult.success =>
          const AppUpdateState(), // Play is restarting the app.
        AppUpdateResult.userDeniedUpdate => const AppUpdateState(
            updateRequired: true,
            message: 'The update was cancelled. It has to be installed before '
                'you can continue.',
          ),
        AppUpdateResult.inAppUpdateFailed => const AppUpdateState(
            updateRequired: true,
            message: 'The update could not be installed. Check your connection '
                'and try again.',
          ),
      };
    } catch (_) {
      state = const AppUpdateState(
        updateRequired: true,
        message: 'The update could not be started. Check your connection and '
            'try again.',
      );
    }
  }
}
