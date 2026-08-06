import 'package:flutter/widgets.dart';

/// Rebuilds everything below it — including the `ProviderScope` — under a fresh
/// [Key], which disposes every provider and drops all in-memory state.
///
/// Needed on logout. Wiping local storage removes the persisted session, but
/// most of the app's providers are root (non-autoDispose) ones that keep the
/// previous user's leads, opportunities, dashboard figures and lookup lists in
/// memory for as long as the process lives. Invalidating them one by one would
/// mean maintaining a list that every new feature has to remember to update;
/// remounting the scope is the only way to be certain nothing survives into the
/// next login.
///
/// The restart key lives in widget state rather than a provider on purpose:
/// this widget sits *above* the `ProviderScope` it recreates, so there is no
/// provider it could read without being destroyed by its own rebuild.
class AppRestart extends StatefulWidget {
  const AppRestart({super.key, required this.child});

  final Widget child;

  /// Discards all state below the nearest [AppRestart] ancestor.
  static void restart(BuildContext context) {
    context.findAncestorStateOfType<_AppRestartState>()?._restart();
  }

  @override
  State<AppRestart> createState() => _AppRestartState();
}

class _AppRestartState extends State<AppRestart> {
  Key _key = UniqueKey();

  void _restart() => setState(() => _key = UniqueKey());

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}
