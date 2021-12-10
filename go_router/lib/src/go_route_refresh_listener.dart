import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'go_router.dart';

/// This class can be used to make `refreshListenable` react to events in the
/// the provided stream. This allows you to listen to stream based state
/// management solutions like for example BLoC.
///
/// {@tool snippet}
/// Typical usage is as follows:
///
/// ```dart
/// GoRouter(
///  refreshListenable: GoRouterRefreshStream(stream),
/// );
/// ```
/// {@end-tool}
class GoRouterRefreshStream extends ChangeNotifier {
  /// Creates a [GoRouterRefreshStream].
  ///
  /// Every time the [stream] receives an event the [GoRouter] will refresh its
  /// current route.
  GoRouterRefreshStream(
    Stream stream,
  ) {
    notifyListeners();
    _streamSub = stream.asBroadcastStream().listen((dynamic _) {
      notifyListeners();
    });
  }

  late final StreamSubscription _streamSub;

  @override
  void dispose() {
    _streamSub.cancel();
    super.dispose();
  }
}
