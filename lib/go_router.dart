library go_router;

import 'package:flutter/widgets.dart';
import 'package:path_to_regexp/path_to_regexp.dart' as p2re;

import 'src/go_router_impl.dart';
import 'src/path_strategy_nonweb.dart' if (dart.library.html) 'src/path_strategy_web.dart';

enum UrlPathStrategy { hash, path }
typedef GoRouteBuilder = Widget Function(BuildContext context, String location);
typedef GoRouteInfoBuilder = List<GoRoute> Function(BuildContext context);
typedef GoRoutePageBuilder = Page<dynamic> Function(BuildContext context, Map<String, String> args);
typedef GoRouteErrorPageBuilder = Page<dynamic> Function(BuildContext context, String location, Exception ex);

class GoRoute {
  final String pattern;
  final GoRoutePageBuilder builder;
  GoRoute({required this.pattern, required this.builder});
}

class GoRouter {
  final _routeInformationParser = GoRouteInformationParser();
  late final GoRouterDelegate _routerDelegate;
  final _locPages = <String, Page<dynamic>>{};

  GoRouter({required GoRouteBuilder builder}) {
    _routerDelegate = GoRouterDelegate(
      // wrap the returned Navigator to enable GoRouter.of(context).go() and context.go()
      builder: (context, location) => InheritedGoRouter(
        goRouter: this,
        child: builder(context, location),
      ),
    );
  }

  GoRouter.routes({required List<GoRoute> routes, required GoRouteErrorPageBuilder error}) {
    _routerDelegate = GoRouterDelegate(
      // wrap the returned Navigator to enable GoRouter.of(context).go() and context.go()
      builder: (context, location) => InheritedGoRouter(
        goRouter: this,
        child: _builder(context, location, routes, error),
      ),
    );
  }

  RouteInformationParser<Object> get routeInformationParser => _routeInformationParser;
  RouterDelegate<Object> get routerDelegate => _routerDelegate;

  void go(String location) => _routerDelegate.go(location);

  static void setUrlPathStrategy(UrlPathStrategy strategy) => setUrlPathStrategyImpl(strategy);
  static String locationFor(String pattern, Map<String, String> args) => p2re.pathToFunction(pattern)(args);
  static GoRouter of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<InheritedGoRouter>()!.goRouter;

  Widget _builder(
    BuildContext context,
    String location,
    List<GoRoute> routes,
    GoRouteErrorPageBuilder error,
  ) {
    print('location= $location');

    // don't recreate the stack if we already have a list of pages that matches the location (popping)
    final popping = _locPages.isNotEmpty && _locPages.keys.last.toLowerCase() == location.toLowerCase();

    if (!popping) {
      // create a new list of pages based on the new location (not popping)
      _locPages.clear();

      try {
        for (final route in routes) {
          final params = <String>[];
          final re = p2re.pathToRegExp(route.pattern, prefix: true, caseSensitive: false, parameters: params);
          final match = re.matchAsPrefix(location);
          if (match == null) continue;

          final args = p2re.extract(params, match);
          final pageLoc = GoRouter.locationFor(route.pattern, args);
          final page = route.builder(context, args);

          if (_locPages.containsKey(pageLoc)) throw Exception('duplicate location: $pageLoc');
          _locPages[pageLoc] = page;
        }

        // if the last route doesn't match exactly, then we haven't got a valid stack of pages;
        // this allows '/' to match as part of a stack of pages but to fail on '/nonsense' OR
        // if we haven't found any matching routes, then we have an error
        if (_locPages.isEmpty || _locPages.keys.last.toString().toLowerCase() != location.toLowerCase()) {
          throw Exception('page not found: $location');
        }
      } on Exception catch (ex) {
        // if there's an error, show an error page
        _locPages.clear();
        _locPages[location] = error(context, location, ex);
      }
    }

    return Navigator(
      pages: _locPages.values.toList(),
      onPopPage: (route, dynamic result) {
        if (!route.didPop(result)) return false;

        // remove the route for the page we're showing and go to the next location down
        assert(_locPages.isNotEmpty);
        _locPages.remove(_locPages.keys.last);
        _routerDelegate.go(_locPages.keys.last);

        return true;
      },
    );
  }
}

extension GoRouterHelper on BuildContext {
  void go(String location) {
    GoRouter.of(this).go(location);
  }
}
