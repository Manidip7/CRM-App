/// Barrel file for the networking layer. Import this single file to get the
/// API client, result/exception types and the Riverpod providers:
///
/// ```dart
/// import 'package:crm_app/core/network/network.dart';
/// ```
library;

export 'api_client.dart';
export 'api_constants.dart';
export 'api_exception.dart';
export 'api_result.dart';
export 'dio_client.dart';
export 'network_providers.dart';
export 'token_storage.dart';
