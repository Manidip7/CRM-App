import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/network_providers.dart';
import 'core/network/persistent_token_storage.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/session_store.dart';
import 'routes/app_routes.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persisted auth data before the app starts so the user stays logged in
  // across restarts: the token (for the auth header) and the full session
  // (user, roles, permissions) for the UI.
  final tokenStorage = await PersistentTokenStorage.load();
  final sessionStore = await SessionStore.load();

  runApp(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokenStorage),
        sessionStoreProvider.overrideWithValue(sessionStore),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}

