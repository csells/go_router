library go_router;

import 'package:flutter/widgets.dart';
import 'package:path_to_regexp/path_to_regexp.dart' as p2re;

import 'src/go_router_impl.dart';
import 'src/path_strategy_nonweb.dart' if (dart.library.html) 'src/path_strategy_web.dart';

enum UrlPathStrategy { hash, path }
typedef GoRouteBuilder = Widget Function(BuildContext context, String location);
typedef GoRouteRoutesBuilder = Iterable<GoRoute> Function(BuildContext context, String location);
typedef GoRoutePageBuilder = Page<dynamic> Function(BuildContext context, Map<String, String> args);
typedef GoRouteErrorPageBuilder = Page<dynamic> Function(BuildContext context, GoRouteException ex);

class GoRouteException implements Exception {
  final String location;
  final Exception nested;
  GoRouteException(this.location, this.nested);

  @override
  String toString() => '$nested: $location';
}

class GoRedirect extends Page<dynamic> {
  final String location;
  const GoRedirect(this.location);

  @override
  Route createRoute(BuildContext context) => throw UnimplementedError();
}

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

  GoRouter.routes({required GoRouteRoutesBuilder builder, required GoRouteErrorPageBuilder error}) {
    _routerDelegate = GoRouterDelegate(
      // wrap the returned Navigator to enable GoRouter.of(context).go() and context.go()
      builder: (context, location) => InheritedGoRouter(
        goRouter: this,
        child: _builder(context, location, builder(context, location), error),
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
    Iterable<GoRoute> routes,
    GoRouteErrorPageBuilder error,
  ) {
    var loc = location;
    Map<String, Page<dynamic>> locPages;
    for (;;) {
      // loop until there's no redirect
      try {
        locPages = _getLocPages(context, loc, routes);
        assert(locPages.isNotEmpty); // an empty set of pages should throw an exception in _getLocPages

        // if the top of the stack isn't a redirect, then stop looping and use this stack
        if (locPages.entries.last.value is! GoRedirect) break;
        assert(locPages.entries.length == 1); // _goLocPages should ensure this

        // if the top page is a redirect, then loop back around to get a stack of new pages
        final redirect = locPages.entries.last.value as GoRedirect;
        final newLoc = redirect.location;
        if (_locationsMatch(newLoc, loc)) throw Exception('redirecting to same location: $loc');

        loc = newLoc;
      } on Exception catch (ex) {
        // if there's an error, show an error page
        locPages = {loc: error(context, GoRouteException(loc, ex))};
        break;
      }
    }

    // create a new list of pages based on the new location
    _locPages.clear();
    _locPages.addAll(locPages);
    assert(_locPages.isNotEmpty);

    return Navigator(
      pages: _locPages.values.toList(),
      onPopPage: (route, dynamic result) {
        if (!route.didPop(result)) return false;

        // remove the route for the page we're showing and go to the next location up
        assert(_locPages.isNotEmpty);
        _locPages.remove(_locPages.keys.last);
        _routerDelegate.go(_locPages.keys.last);

        return true;
      },
    );
  }

  static Map<String, Page<dynamic>> _getLocPages(BuildContext context, String location, Iterable<GoRoute> routes) {
    final locPages = <String, Page<dynamic>>{};
    for (final route in routes) {
      final params = <String>[];
      final re = p2re.pathToRegExp(route.pattern, prefix: true, caseSensitive: false, parameters: params);
      final match = re.matchAsPrefix(location);
      if (match == null) continue;

      final args = p2re.extract(params, match);
      final pageLoc = GoRouter.locationFor(route.pattern, args);
      final page = route.builder(context, args);

      if (locPages.containsKey(pageLoc)) throw Exception('duplicate location $pageLoc');
      locPages[pageLoc] = page;
    }

    // if the top location doesn't match the target location exactly, then we haven't got a valid stack of pages;
    // this allows '/' to match as part of a stack of pages but to fail on '/nonsense'
    final topMatches = locPages.isNotEmpty && _locationsMatch(locPages.keys.last, location);
    if (!topMatches) throw Exception('page not found');

    // if the top page on the stack is a redirect, just return it
    if (locPages.entries.last.value is GoRedirect) return Map.fromEntries([locPages.entries.last]);

    // otherwise, ignore intermediate redirects and use this stack
    locPages.removeWhere((key, value) => value is GoRedirect);
    if (locPages.isEmpty) throw Exception('page not found');
    return locPages;
  }

  static bool _locationsMatch(String loc1, String loc2) {
    // check just the path w/o the queryParameters
    final uri1 = Uri.tryParse(loc1);
    final uri2 = Uri.tryParse(loc2);
    return uri1 != null && uri2 != null && uri1.path.toLowerCase().trim() == uri2.path.toLowerCase().trim();
  }
}

extension GoRouterHelper on BuildContext {
  void go(String location) => GoRouter.of(this).go(location);
}
