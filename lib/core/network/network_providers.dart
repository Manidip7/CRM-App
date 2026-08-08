import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'dio_client.dart';
import 'server_config.dart';
import 'token_storage.dart';

/// Holds the auth token. Swap [InMemoryTokenStorage] for a persistent
/// implementation by overriding this provider in `ProviderScope`.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return InMemoryTokenStorage();
});

/// Where the saved server lives on disk. Overridden in `main` with the instance
/// loaded before `runApp`.
final serverConfigStoreProvider = Provider<ServerConfigStore>((ref) {
  throw UnimplementedError('serverConfigStoreProvider must be overridden');
});

/// The server this device talks to, or null until the setup screen has been
/// completed. Writing to it re-creates [dioProvider] against the new address.
class ServerConfigNotifier extends Notifier<ServerConfig?> {
  @override
  ServerConfig? build() => ref.read(serverConfigStoreProvider).cached;

  Future<void> save(ServerConfig config) async {
    await ref.read(serverConfigStoreProvider).save(config);
    state = config;
  }

  /// Forgets the server, sending the app back to the setup screen.
  Future<void> clear() async {
    await ref.read(serverConfigStoreProvider).clear();
    state = null;
  }
}

final serverConfigProvider =
    NotifierProvider<ServerConfigNotifier, ServerConfig?>(
      ServerConfigNotifier.new,
    );

/// Emits an incrementing counter whenever the backend rejects the token (401).
/// Listen to this from your router/root widget to bounce the user back to the
/// login screen on a forced logout.
class UnauthorizedNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void signal() => state = state + 1;
}

final unauthorizedProvider =
    NotifierProvider<UnauthorizedNotifier, int>(UnauthorizedNotifier.new);

/// The configured [Dio] instance. Recreated if the token storage or the chosen
/// server changes, so switching servers re-points every repository at once.
final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final server = ref.watch(serverConfigProvider);
  final dio = DioClient.create(
    tokenStorage: tokenStorage,
    baseUrl: server?.apiBaseUrl,
    onUnauthorized: () {
      // Notify listeners (router/UI) so they can react to a forced logout.
      ref.read(unauthorizedProvider.notifier).signal();
    },
  );
  ref.onDispose(dio.close);
  return dio;
});

/// The high-level API client every repository depends on.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider));
});
