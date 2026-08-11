import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/utils/AppColors.dart';
import '../../../routes/app_routes.dart';
import '../../auth/data/auth_repository.dart';

/// Whether the splash has already run this process. It is a top-level variable
/// rather than provider state on purpose: it has to survive `AppRestart`, which
/// throws away the whole `ProviderScope`. Without it, logging out would replay
/// the splash — two seconds of branding the user has already sat through.
bool appBootstrapped = false;

/// First screen shown on launch: shows the branding briefly, then routes the
/// user onward — to the dashboard if a session was restored, otherwise to the
/// login screen.
///
/// It asks for **no** permissions. The call-log permission used to be requested
/// here, which broke Google Play's prominent disclosure rule: the prompt landed
/// before login, with no explanation of why the app wanted call history. It now
/// happens at the moment the user taps Call, behind
/// `ensureCallLogAccess` (lib/features/calls/widget/call_log_disclosure.dart).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(seconds: 2));

    appBootstrapped = true;
    if (!mounted) return;

    // First launch (or after "change server"): the app doesn't know which CRM
    // to talk to yet, so nothing else can happen until that's chosen.
    if (ref.read(serverConfigProvider) == null) {
      context.go(AppRoutes.serverSetup);
      return;
    }

    // Route based on the restored session: straight to the dashboard if the
    // user is already logged in, otherwise to the login screen.
    final loggedIn = ref.read(authSessionProvider) != null;
    context.go(loggedIn ? AppRoutes.dashboard : AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/splassscreenimage.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
