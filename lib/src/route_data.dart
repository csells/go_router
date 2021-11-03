// ignore_for_file: public_member_api_docs

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta_meta.dart';

import 'go_route.dart';
import 'go_router_state.dart';

/// Baseclass for types that wish to play along her.
///
/// This looks like [StatelessWidget] – I don't think we want to subclass,
/// though.
// TODO: we could have MaterialRouteData & CupertinoRouteData
abstract class RouteData {
  const RouteData();

  /// Override this in a subclass to change the type of page created.
  Page<dynamic> createPage(
    BuildContext context,
    GoRouterState state,
  );

  String? redirect(GoRouterState state) => null;

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
    required RouteData Function(GoRouterState) factory,
    List<GoRoute> routes = const [],
  }) =>
      GoRoute(
        path: path,
        pageBuilder: _createPageHelper(factory),
        redirect: _createRedirectHelper(factory),
        routes: routes,
      );

  static Page<dynamic> Function(BuildContext, GoRouterState) _createPageHelper(
    RouteData Function(GoRouterState) factory,
  ) =>
      (context, state) {
        final data = factory(state);
        return data.createPage(context, state);
      };

  static String? Function(GoRouterState) _createRedirectHelper(
    RouteData Function(GoRouterState) factory,
  ) =>
      (state) => factory(state).redirect(state);
}

abstract class CupertinoRouteData extends RouteData {
  const CupertinoRouteData();

  Widget build(BuildContext context);

  /// Override this in a subclass to change the type of page created.
  @override
  Page<dynamic> createPage(
    BuildContext context,
    GoRouterState state,
  ) =>
      CupertinoPage<dynamic>(
        key: state.pageKey,
        child: build(context),
      );
}

abstract class MaterialRouteData extends RouteData {
  const MaterialRouteData();

  Widget build(BuildContext context);

  /// Override this in a subclass to change the type of page created.
  @override
  Page<dynamic> createPage(
    BuildContext context,
    GoRouterState state,
  ) =>
      MaterialPage<dynamic>(
        key: state.pageKey,
        child: build(context),
      );
}

/// The annotation we use! Annotating the source library seems to be a good
/// idea, but open to discuss.
@Target({TargetKind.library, TargetKind.classType})
class RouteDef<T extends RouteData> {
  const RouteDef({
    required this.path,
    this.builder,
    this.children = const [],
  });

  final String path;
  final Function? builder;
  final List<RouteDef> children;
}
