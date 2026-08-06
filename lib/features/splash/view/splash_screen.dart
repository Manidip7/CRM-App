import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/AppColors.dart';
import '../../../routes/app_routes.dart';
import '../../auth/data/auth_repository.dart';
import '../../calls/data/call_log_service.dart';

/// Whether the splash has already run this process. It is a top-level variable
/// rather than provider state on purpose: it has to survive `AppRestart`, which
/// throws away the whole `ProviderScope`. Without it, logging out would replay
/// the splash — two seconds of branding plus a repeat of the permission prompt
/// the user already answered.
bool appBootstrapped = false;

/// First screen shown on launch. It requests the app's runtime permissions
/// (the call-log permission) up front, then routes the user onward — to the
/// dashboard if a session was restored, otherwise to the login screen.
///
/// Gating navigation behind the permission request guarantees the order the
/// product wants: permissions first, login screen after.
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
    await Future.wait([
      ref.read(callLogServiceProvider).ensurePermission(request: true),
      Future<void>.delayed(const Duration(seconds: 2)),
    ]);

    appBootstrapped = true;
    if (!mounted) return;

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
