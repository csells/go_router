// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:meta/meta_meta.dart';

import 'go_router.dart';
import 'go_router_state.dart';
import 'typedefs.dart';

/// Helper function used in generated code.
///
/// Also demonstrates that the "type" of page created could easily be configured
/// via the annotation and doesn't need to be hard-wired into [RouteData].
GoRouterPageBuilder $materialPageFactory(
  RouteData Function(GoRouterState) factory,
) =>
    (context, state) => MaterialPage<dynamic>(
          key: state.pageKey,
          child: factory(state).build(context),
        );

/// Helper class used in generated code.
///
/// Represents the source/target of decode/encode for [RouteData]
/// implementations.
class $PathData {
  $PathData(
    this.name, {
    this.params = const {},
    this.queryParams = const {},
  });

  final String name;
  final Map<String, String> params;
  final Map<String, String> queryParams;

  String namedLocation(BuildContext buildContext) => buildContext.namedLocation(
        name,
        params: params,
        queryParams: queryParams,
      );

  void go(BuildContext buildContext, {Object? extra}) => buildContext.go(
        namedLocation(buildContext),
        extra: extra,
      );
}

/// Baseclass for types that wish to play along her.
///
/// This looks like [StatelessWidget] – I don't think we want to subclass,
/// though.
abstract class RouteData {
  Widget build(BuildContext context);
}

/// The annotation we use! Annotating the source library seems to be a good
/// idea, but open to discuss.
@Target({TargetKind.library})
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
