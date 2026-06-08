import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'dio_client.dart';
import 'token_storage.dart';

/// Holds the auth token. Swap [InMemoryTokenStorage] for a persistent
/// implementation by overriding this provider in `ProviderScope`.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return InMemoryTokenStorage();
});

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

/// The configured [Dio] instance. Recreated if [tokenStorageProvider] changes.
final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final dio = DioClient.create(
    tokenStorage: tokenStorage,
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
