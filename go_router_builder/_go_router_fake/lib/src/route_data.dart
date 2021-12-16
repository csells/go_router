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
class TypedGoRoute<T extends GoRouteData> {
  const TypedGoRoute({
    required this.path,
    this.routes = const [],
  });

  final String path;
  final List<TypedGoRoute> routes;
}

abstract class GoRouterState {
  Object? get extra;
  Map<String, String> get params;
  Map<String, String> get queryParams;
}
