import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Saves bytes into the device's public Downloads folder via a native
/// MethodChannel (MediaStore on Android 10+, the legacy Downloads dir below).
/// Only implemented on Android; returns null on other platforms.
class DownloadsSaver {
  DownloadsSaver._();

  static const MethodChannel _channel = MethodChannel('crm_app/downloads');

  /// Writes [bytes] as [filename] (with the given [mime]) to public Downloads.
  /// Returns a user-facing path (e.g. `Download/quotation-2.pdf`) on success, or
  /// null when the platform isn't supported. Throws [PlatformException] on a
  /// native save failure.
  static Future<String?> saveToDownloads({
    required Uint8List bytes,
    required String filename,
    String mime = 'application/pdf',
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    return _channel.invokeMethod<String>('saveToDownloads', {
      'bytes': bytes,
      'filename': filename,
      'mime': mime,
    });
  }
}
