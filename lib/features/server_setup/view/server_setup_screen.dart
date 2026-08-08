import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/utils/AppColors.dart';
import '../../../routes/app_routes.dart';
import '../provider/server_setup_provider.dart';
import 'qr_scanner_screen.dart';

/// First-launch step: point the app at the company's CRM server, either by
/// typing the address or scanning the admin's QR code. The address is looked up
/// through `POST /api/v1/tenant-info` before it is saved, so a typo is caught
/// here rather than surfacing as a mysterious login failure later — and the
/// tenant's real domain, not the typed one, becomes the app's base URL.
///
/// Shown once — every later launch goes straight from the splash to login.
/// All state lives in Riverpod (no [setState]).
class ServerSetupScreen extends ConsumerStatefulWidget {
  const ServerSetupScreen({super.key});

  @override
  ConsumerState<ServerSetupScreen> createState() => _ServerSetupScreenState();
}

class _ServerSetupScreenState extends ConsumerState<ServerSetupScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Coming back here after a sign-out or a "change server" shouldn't mean
    // hunting for the link again — offer whatever this device last used. The
    // draft outlives this screen while the controller does not, so the field
    // has to be re-seeded on every visit, not only the first.
    final draft = ref.read(serverUrlDraftProvider);
    final seed = draft.isNotEmpty
        ? draft
        : (ref.read(serverConfigStoreProvider).lastAddress ?? '');
    _controller.text = seed;

    // Writing to a provider during the first build isn't allowed, so the draft
    // catches up once the frame is done.
    if (seed.isNotEmpty && seed != draft) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(serverUrlDraftProvider.notifier).set(seed);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(serverSetupControllerProvider);
    final draft = ref.watch(serverUrlDraftProvider);
    final canConnect = draft.trim().isNotEmpty && !setup.isChecking;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 36),
                  _buildBrand(),
                  const SizedBox(height: 32),
                  _buildTitle(),
                  const SizedBox(height: 24),
                  _buildUrlField(setup.isChecking),
                  if (setup.error != null) ...[
                    const SizedBox(height: 12),
                    _buildError(setup.error!),
                  ],
                  const SizedBox(height: 18),
                  _buildConnectButton(canConnect, setup.isChecking),
                  const SizedBox(height: 18),
                  _buildDivider(),
                  const SizedBox(height: 18),
                  _buildScanButton(setup.isChecking),
                  // A Spacer would need a bounded height, which a scroll view
                  // never gives its child — fixed gap instead.
                  const SizedBox(height: 32),
                  _buildFooterHint(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildBrand() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Image(
              image: AssetImage('assets/images/logonoborder.png'),
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Peplo CRM',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect to your CRM',
          style: GoogleFonts.poppins(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Enter the CRM address your admin gave you, or scan their QR code. '
          'You only have to do this once.',
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Address field ──
  Widget _buildUrlField(bool busy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CRM ADDRESS',
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: _controller,
            enabled: !busy,
            autocorrect: false,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            onChanged: (value) {
              ref.read(serverUrlDraftProvider.notifier).set(value);
              ref.read(serverSetupControllerProvider.notifier).clearError();
            },
            onSubmitted: (_) => _connect(),
            decoration: InputDecoration(
              hintText: 'yourcompany.peplocrm.in',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textLight,
              ),
              prefixIcon: const Icon(
                Icons.link_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textLight,
                      ),
                      onPressed: busy ? null : _clear,
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Example: https://yourcompany.peplocrm.in',
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColors.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AppColors.red,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ──
  Widget _buildConnectButton(bool enabled, bool busy) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? _connect : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.35),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: busy
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Checking address…',
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Text(
                'Connect',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }

  Widget _buildScanButton(bool busy) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: busy ? null : _scan,
        icon: const Icon(
          Icons.qr_code_scanner_rounded,
          size: 20,
          color: AppColors.primary,
        ),
        label: Text(
          'Scan QR Code',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.cardBackground,
          side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterHint() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 14,
            color: AppColors.textLight,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Your data stays on your company\'s own server',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: AppColors.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Behaviour ──
  void _clear() {
    _controller.clear();
    ref.read(serverUrlDraftProvider.notifier).set('');
    ref.read(serverSetupControllerProvider.notifier).clearError();
  }

  Future<void> _scan() async {
    final scanned = await QrScannerScreen.open(context);
    if (scanned == null || !mounted) return;

    // Fill the field in so the user can see (and fix) what was scanned, then
    // check it straight away — scanning should feel like one action.
    _controller.text = scanned;
    ref.read(serverUrlDraftProvider.notifier).set(scanned);
    ref.read(serverSetupControllerProvider.notifier).clearError();
    await _connect();
  }

  Future<void> _connect() async {
    final url = ref.read(serverUrlDraftProvider).trim();
    if (url.isEmpty) return;
    FocusScope.of(context).unfocus();

    final ok = await ref
        .read(serverSetupControllerProvider.notifier)
        .connect(url);
    if (!mounted || !ok) return;

    final config = ref.read(serverSetupControllerProvider).config;
    final name = config?.companyName?.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          name?.isNotEmpty ?? false
              ? 'Connected to $name'
              : 'Connected to ${config?.displayHost ?? 'your CRM'}',
          style: const TextStyle(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
    context.go(AppRoutes.login);
  }
}
