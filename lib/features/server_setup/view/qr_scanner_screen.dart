import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/utils/AppColors.dart';

/// Full-screen QR reader for the setup step. Pops with the address found in the
/// code, or null if the user backs out.
///
/// Opened by [ServerSetupScreen]; the camera permission prompt is raised by the
/// scanner itself the first time this screen is shown.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  /// Shows the scanner and returns the scanned address, or null.
  static Future<String?> open(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
  }

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  /// Detection keeps firing for a moment after the first hit; without this the
  /// screen would try to pop several times.
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final url = _extractUrl(barcode.rawValue);
      if (url != null) {
        _handled = true;
        Navigator.of(context).pop(url);
        return;
      }
    }
  }

  /// QR codes in the wild carry either the bare address or a small JSON blob
  /// from the admin panel — accept both rather than making the user retype.
  static String? _extractUrl(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;

    if (value.startsWith('{')) {
      try {
        final map = (jsonDecode(value) as Map).cast<String, dynamic>();
        for (final key in const ['url', 'base_url', 'server', 'server_url']) {
          final found = map[key];
          if (found is String && found.trim().isNotEmpty) return found.trim();
        }
        return null;
      } catch (_) {
        return null;
      }
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _buildCameraError(error),
          ),
          _buildOverlay(),
          _buildTopBar(),
          _buildHint(),
        ],
      ),
    );
  }

  /// Camera unavailable or permission refused — say what to do about it instead
  /// of leaving a black screen.
  Widget _buildCameraError(MobileScannerException error) {
    final denied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            denied ? Icons.no_photography_outlined : Icons.videocam_off_rounded,
            color: Colors.white70,
            size: 46,
          ),
          const SizedBox(height: 16),
          Text(
            denied
                ? 'Camera permission is off'
                : 'The camera could not be started',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            denied
                ? 'Allow camera access in Settings to scan the QR code, or go '
                      'back and type the address instead.'
                : 'Go back and type the address instead.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 22),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Enter address manually',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dimmed backdrop with a clear cut-out, so it's obvious where to aim. The
  /// hole is punched with `srcOut`: the dark layer is painted everywhere the
  /// inner square is *not*.
  Widget _buildOverlay() {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest.shortestSide * 0.68;
          final window = Center(
            child: SizedBox(
              width: size,
              height: size,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Color(0xAA000000),
                  BlendMode.srcOut,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        backgroundBlendMode: BlendMode.dstOut,
                      ),
                    ),
                    window,
                  ],
                ),
              ),
              Center(
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(
          children: [
            _circleButton(
              Icons.arrow_back_rounded,
              () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            _circleButton(Icons.flash_on_rounded, _controller.toggleTorch),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: Color(0x55000000),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 21),
      ),
    );
  }

  Widget _buildHint() {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Scan your CRM QR code',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Point the camera at the code your admin shared',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 18),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.keyboard_alt_outlined,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(
                  'Type it instead',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
