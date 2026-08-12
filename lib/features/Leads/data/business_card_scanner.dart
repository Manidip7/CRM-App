import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../model/business_card_data.dart';

/// Reads the text off a photographed business card.
///
/// This is the only place the app talks to ML Kit. It runs entirely on the
/// device — no image ever leaves the phone and the scanner works with no
/// network — and it hands back plain [OcrLine]s so `BusinessCardParser` stays
/// independent of the OCR engine.
class BusinessCardScanner {
  const BusinessCardScanner();

  /// Recognises the text in the image at [imagePath].
  ///
  /// [page] distinguishes the front of a card (`0`) from the back (`1`) so the
  /// parser can keep each side's reading order intact when both are scanned.
  ///
  /// Throws [BusinessCardScanException] when the engine cannot read the file at
  /// all; an image with no text simply comes back empty.
  Future<List<OcrLine>> recognise(String imagePath, {int page = 0}) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result =
          await recognizer.processImage(InputImage.fromFilePath(imagePath));
      final lines = <OcrLine>[];
      for (final block in result.blocks) {
        for (final line in block.lines) {
          final box = line.boundingBox;
          lines.add(OcrLine(
            text: line.text,
            left: box.left,
            top: box.top,
            width: box.width,
            height: box.height,
            page: page,
          ));
        }
      }
      return lines;
    } catch (e) {
      throw BusinessCardScanException(
        'Could not read this image. Please try again with a clearer photo.',
        cause: e,
      );
    } finally {
      // Always release the native detector, even when recognition threw —
      // leaking one per scan would exhaust the device after a few cards.
      await recognizer.close();
    }
  }
}

/// Raised when the OCR engine itself fails (unreadable file, missing model).
class BusinessCardScanException implements Exception {
  final String message;
  final Object? cause;

  const BusinessCardScanException(this.message, {this.cause});

  @override
  String toString() => 'BusinessCardScanException: $message';
}
