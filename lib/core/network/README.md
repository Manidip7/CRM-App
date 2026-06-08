# Networking layer

Dio-based API + error-handling stack for the CRM app. Everything is wired
through Riverpod providers.

## Files

| File | Responsibility |
|------|----------------|
| `api_constants.dart` | Base URL, timeouts, endpoint paths. **Set `baseUrl` here.** |
| `dio_client.dart` | Builds the configured `Dio` instance + interceptor chain. |
| `api_client.dart` | Generic GET/POST/PUT/PATCH/DELETE → returns `ApiResult<T>`. |
| `api_result.dart` | `Success` / `Failure` sealed result type. |
| `api_exception.dart` | Typed `ApiException` + `ApiErrorType`; maps every `DioException`. |
| `token_storage.dart` | Auth-token storage interface (swap in secure storage for prod). |
| `interceptors/auth_interceptor.dart` | Adds `Bearer` token, handles 401. |
| `interceptors/logging_interceptor.dart` | Debug-only request/response logging. |
| `network_providers.dart` | Riverpod providers: `apiClientProvider`, `tokenStorageProvider`, `unauthorizedProvider`. |
| `network.dart` | Barrel export. |

## Using it from a repository

```dart
class LeadsRepository {
  final ApiClient _api;
  LeadsRepository(this._api);

  Future<ApiResult<List<LeadModel>>> getLeads() {
    return _api.get(
      ApiConstants.leads,
      decoder: (json) => (json as List)
          .map((e) => LeadModel.fromJson(e))
          .toList(),
    );
  }
}

final leadsRepositoryProvider =
    Provider((ref) => LeadsRepository(ref.watch(apiClientProvider)));
```

See `features/auth/data/auth_repository.dart` and
`features/Leads/data/leads_repository.dart` for full examples.

## Handling the result in a provider / UI

```dart
final result = await ref.read(leadsRepositoryProvider).getLeads();
result.when(
  success: (leads) => state = AsyncData(leads),
  failure: (err) {
    // err.message is safe to show; err.type lets you branch.
    if (err.isUnauthorized) { /* go to login */ }
    state = AsyncError(err, StackTrace.current);
  },
);
```

## Forced logout on 401

`AuthInterceptor` clears the token and bumps `unauthorizedProvider` on any 401.
Listen to it once near the root of the app:

```dart
ref.listen(unauthorizedProvider, (_, __) {
  // navigate back to LoginScreen
});
```

## For production
- Point `ApiConstants.baseUrl` at the real backend.
- Replace `InMemoryTokenStorage` with a persistent one (e.g.
  `flutter_secure_storage`) by overriding `tokenStorageProvider` in
  `ProviderScope(overrides: [...])`.
