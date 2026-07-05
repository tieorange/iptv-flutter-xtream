import 'dart:async';

import 'package:flutter/foundation.dart';

/// go_router's [refreshListenable] wants a [Listenable]; a Cubit only exposes
/// a [Stream]. This bridges the two so login/logout re-runs the router's
/// top-level redirect without a manual `GoRouter.of(context).refresh()` call.
class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
