// ignore_for_file: public_member_api_docs

import 'package:meta/meta_meta.dart';

abstract class GoRouteData {
  const GoRouteData();

  static String $location(String path, {Map<String, String>? queryParams}) =>
      throw UnimplementedError();
  static GoRoute $route({
    required String path,
    required GoRouteData Function(GoRouterState) factory,
    List<GoRoute> routes = const [],
  }) =>
      throw UnimplementedError();
}

abstract class GoRoute {}

@Target({TargetKind.library, TargetKind.classType})
class RouteDef<T extends GoRouteData> {
  const RouteDef({
    required this.path,
    this.children = const [],
  });

  final String path;
  final List<RouteDef> children;
}

abstract class GoRouterState {
  Object? get extra;
  Map<String, String> get params;
  Map<String, String> get queryParams;
}
