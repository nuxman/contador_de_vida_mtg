import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/providers/match_provider.dart';
import '../presentation/screens/setup_screen.dart';
import '../presentation/screens/table_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const TableScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupScreen(),
      ),
    ],
    redirect: (context, state) {
      final storage = ref.read(matchStorageProvider);
      final hasSavedMatch = storage.readMatch() != null;
      final onSetup = state.matchedLocation == '/setup';

      if (!hasSavedMatch && !onSetup) {
        return '/setup';
      }
      return null;
    },
  );
});

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this.ref) {
    ref.listen(matchProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref ref;
}
