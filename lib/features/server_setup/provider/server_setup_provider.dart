import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/network/server_config.dart';
import '../data/server_setup_repository.dart';

/// Where the setup screen is in the connect flow. All of it lives in Riverpod
/// so the screen itself stays free of [setState].
enum ServerSetupStatus { idle, checking, connected, failed }

class ServerSetupState {
  final ServerSetupStatus status;

  /// The verified server, once the check has passed — drives the brief
  /// "Connected to <company>" confirmation before the login screen.
  final ServerConfig? config;

  /// User-facing failure text, shown under the address field.
  final String? error;

  const ServerSetupState({
    this.status = ServerSetupStatus.idle,
    this.config,
    this.error,
  });

  bool get isChecking => status == ServerSetupStatus.checking;
  bool get isConnected => status == ServerSetupStatus.connected;
}

/// Looks up the address the user typed or scanned, and on success saves the
/// tenant's own domain as the app's server.
class ServerSetupController extends Notifier<ServerSetupState> {
  @override
  ServerSetupState build() => const ServerSetupState();

  /// Clears a previous failure as soon as the user edits the address, so the
  /// red box doesn't sit there contradicting what's now in the field.
  void clearError() {
    if (state.error != null) state = const ServerSetupState();
  }

  /// Looks [url] up and, if a CRM is found, stores its domain as the app's
  /// server. Returns true when the app is ready to move on to login.
  Future<bool> connect(String url) async {
    if (state.isChecking) return false;
    state = const ServerSetupState(status: ServerSetupStatus.checking);

    try {
      final config = await ref.read(serverSetupRepositoryProvider).verify(url);
      // Saved before navigating, so the login screen's very first request
      // already goes to the right host.
      await ref.read(serverConfigProvider.notifier).save(config);
      state = ServerSetupState(
        status: ServerSetupStatus.connected,
        config: config,
      );
      return true;
    } on ServerSetupException catch (e) {
      state = ServerSetupState(
        status: ServerSetupStatus.failed,
        error: e.message,
      );
      return false;
    } catch (e) {
      state = const ServerSetupState(
        status: ServerSetupStatus.failed,
        error: 'Something went wrong while checking that address.',
      );
      return false;
    }
  }
}

final serverSetupControllerProvider =
    NotifierProvider<ServerSetupController, ServerSetupState>(
      ServerSetupController.new,
    );

/// The address currently typed into the setup screen's field. Kept in Riverpod
/// so the QR scanner can fill it in and the Connect button can enable itself
/// without the screen holding local state.
class ServerUrlDraft extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final serverUrlDraftProvider = NotifierProvider<ServerUrlDraft, String>(
  ServerUrlDraft.new,
);
