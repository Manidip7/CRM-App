import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app/app_restart.dart';
import 'core/network/network_providers.dart';
import 'core/network/persistent_token_storage.dart';
import 'core/network/server_config.dart';
import 'core/permissions/permissions.dart';
import 'core/update/app_update_provider.dart';
import 'core/update/update_gate.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/session_store.dart';
import 'features/calls/provider/call_providers.dart';
import 'routes/app_routes.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persisted auth data before the app starts so the user stays logged in
  // across restarts: the token (for the auth header), the full session (user,
  // roles, permissions) for the UI, and the last known permission map so the
  // very first frame already hides what this role can't see.
  final tokenStorage = await PersistentTokenStorage.load();
  final sessionStore = await SessionStore.load();
  final permissionsStore = await PermissionsStore.load();
  // Which CRM server this device is pointed at, chosen on the setup screen the
  // first time the app runs. Loaded here so the first frame already knows
  // whether that step is still pending.
  final serverConfigStore = await ServerConfigStore.load();

  runApp(
    // [AppRestart] sits above the scope so logout can recreate it, dropping
    // every provider that still holds the signed-out user's data. The store
    // instances are reused across a restart — they read from disk, which the
    // logout has already emptied.
    AppRestart(
      child: ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          sessionStoreProvider.overrideWithValue(sessionStore),
          permissionsStoreProvider.overrideWithValue(permissionsStore),
          serverConfigStoreProvider.overrideWithValue(serverConfigStore),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ask Play whether a newer build is live. Deferred by a frame so the first
    // frame isn't held up by a platform call; on a Play-installed device with
    // an update waiting, Play's update sheet comes up right after it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(appUpdateProvider.notifier).check();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Whenever the app comes back to the foreground (e.g. after the user
  /// returns from the phone dialer), scan the device call log and upload any
  /// new calls. No-ops on iOS / when the permission isn't granted.
  ///
  /// The update check runs here too: it catches a version published while the
  /// app sat in the background, and Play requires an interrupted immediate
  /// update to be resumed on the next foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(callSyncControllerProvider.notifier).syncNow();
      ref.read(appUpdateProvider.notifier).check();
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // Above every route, so the update screen covers whatever the user was
      // on and no navigation can slip behind it.
      builder: (context, child) =>
          UpdateGate(child: child ?? const SizedBox.shrink()),
      routerConfig: ref.watch(routerProvider),
    );
  }
}

