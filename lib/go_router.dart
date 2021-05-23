library go_router;

import 'package:flutter/widgets.dart';
import 'package:path_to_regexp/path_to_regexp.dart' as p2re;
import 'src/go_router_impl.dart';

typedef GoRouteInfoBuilder = List<GoRoute> Function(BuildContext context);
typedef GoRoutePageBuilder = Page<dynamic> Function(BuildContext context, Map<String, String> args);
typedef GoRouteErrorPageBuilder = Page<dynamic> Function(BuildContext context, String location, Exception ex);

class GoRoute {
  final String pattern;
  final GoRoutePageBuilder builder;
  GoRoute({required this.pattern, required this.builder});
}

class GoRouter {
  final GoRouteInfoBuilder builder;
  final GoRouteErrorPageBuilder error;
  final _routeInformationParser = GoRouteInformationParser();
  late final GoRouterDelegate _routerDelegate;

  GoRouter({required this.builder, required this.error}) {
    _routerDelegate = GoRouterDelegate(goRouter: this);
  }

  GoRouter.routes({required List<GoRoute> routes, required GoRouteErrorPageBuilder error})
      : this(builder: (context) => routes, error: error);

  RouteInformationParser<Object> get routeInformationParser => _routeInformationParser;
  RouterDelegate<Object> get routerDelegate => _routerDelegate;

  void go(String location) {
    _routerDelegate.go(location);
  }

  static String locationFor(String pattern, Map<String, String> args) => p2re.pathToFunction(pattern)(args);
  static GoRouter of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<InheritedGoRouter>()!.goRouter;
}

extension GoRouterHelper on BuildContext {
  void go(String location) {
    GoRouter.of(this).go(location);
  }
}
