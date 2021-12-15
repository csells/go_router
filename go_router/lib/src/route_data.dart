// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';
import 'package:meta/meta_meta.dart';

import 'go_route.dart';
import 'go_router_state.dart';

/// Baseclass for types that wish to play along her.
///
/// This looks like [StatelessWidget] – I don't think we want to subclass,
/// though.
abstract class GoRouteData {
  const GoRouteData();

  Widget build(BuildContext context) =>
      throw UnsupportedError('Should be overridden in subclass.');

  String? redirect() => null;

  static String $location(String path, {Map<String, String>? queryParams}) =>
      Uri.parse(path)
          .replace(
            queryParameters:
                // Avoid `?` in generated location if `queryParams` is empty
                queryParams == null || queryParams.isEmpty ? null : queryParams,
          )
          .toString();

  static GoRoute $route({
    required String path,
    required GoRouteData Function(GoRouterState) factory,
    List<GoRoute> routes = const [],
  }) =>
      GoRoute(
        path: path,
        builder: _createPageHelper(factory),
        redirect: _createRedirectHelper(factory),
        routes: routes,
      );

  static Widget Function(BuildContext, GoRouterState) _createPageHelper(
    GoRouteData Function(GoRouterState) factory,
  ) =>
      (context, state) {
        final data = factory(state);
        return data.build(context);
      };

  static String? Function(GoRouterState) _createRedirectHelper(
    GoRouteData Function(GoRouterState) factory,
  ) =>
      (state) => factory(state).redirect();
}

/// The annotation we use! Annotating the source library seems to be a good
/// idea, but open to discuss.
@Target({TargetKind.library, TargetKind.classType})
class RouteDef<T extends GoRouteData> {
  const RouteDef({
    required this.path,
    this.children = const [],
  });

  final String path;
  final List<RouteDef> children;
}
