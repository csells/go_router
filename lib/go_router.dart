/// A declarative router for Flutter based on Navigation 2 supporting
/// deep linking, data-driven routes and more
library go_router;

import 'package:flutter/widgets.dart';

import 'src/go_router.dart';

export 'src/custom_transition_page.dart';
export 'src/go_route.dart';
export 'src/go_router.dart';
export 'src/go_router_state.dart';
export 'src/typedefs.dart' show GoRouterPageBuilder, GoRouterRedirect;
export 'src/url_path_strategy.dart';

/// Dart extension to add navigation function to a BuildContext object, e.g.
/// context.go('/');
// NOTE: adding this here instead of in /src to work-around a Dart analyzer bug
// and fix: https://github.com/csells/go_router/issues/116
extension GoRouterHelper on BuildContext {
  /// Get a location from route name and parameters.
  String namedLocation(
    String name, {
    Map<String, String> params = const {},
    Map<String, String> queryParams = const {},
  }) =>
      GoRouter.of(this)
          .namedLocation(name, params: params, queryParams: queryParams);

  /// Navigate to a location.
  void go(String location, {Object? extra}) =>
      GoRouter.of(this).go(location, extra: extra);

  /// Navigate to a named route.
  void goNamed(
    String name, {
    Map<String, String> params = const {},
    Map<String, String> queryParams = const {},
    Object? extra,
  }) =>
      GoRouter.of(this).goNamed(
        name,
        params: params,
        queryParams: queryParams,
        extra: extra,
      );

  /// Push a location onto the page stack.
  void push(String location, {Object? extra}) =>
      GoRouter.of(this).push(location, extra: extra);

  /// Replace the top page in the stack by the given location. 
  void pushReplacement(String location, {Object? extra}) =>
      GoRouter.of(this).pushReplacement(location, extra: extra);

  /// Navigate to a named route onto the page stack.
  void pushNamed(
    String name, {
    Map<String, String> params = const {},
    Map<String, String> queryParams = const {},
    Object? extra,
  }) =>
      GoRouter.of(this).pushNamed(
        name,
        params: params,
        queryParams: queryParams,
        extra: extra,
      );

  /// Replace the top page in the stack by the given named route. 
  void pushReplacementNamed(
    String name, {
    Map<String, String> params = const {},
    Map<String, String> queryParams = const {},
    Object? extra,
  }) =>
      GoRouter.of(this).pushReplacementNamed(
        name,
        params: params,
        queryParams: queryParams,
        extra: extra,
      );
  
  /// Pop the top page off the Navigator's page stack by calling
  /// [Navigator.pop].
  void pop() => GoRouter.of(this).pop(this);
}
