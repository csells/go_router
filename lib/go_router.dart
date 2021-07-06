library go_router;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:path_to_regexp/path_to_regexp.dart' as p2re;

import 'src/go_router_impl.dart';
import 'src/path_strategy_nonweb.dart'
    if (dart.library.html) 'src/path_strategy_web.dart';

/// for use in GoRouter.setUrlPathStrategy
enum UrlPathStrategy { hash, path }

/// the signature of the function to pass to the GoRouter.builder ctor
typedef GoRouterWidgetBuilder = Widget Function(
  BuildContext context,
  String location,
);

/// the signature of the routes builder function to pass to the GoRouter ctor
typedef GoRouterRoutesBuilder = Iterable<GoRoute> Function(
  BuildContext context,
  String location,
);

/// the signature of the page builder callback for a matched GoRoute
typedef GoRouterPageBuilder = Page<dynamic> Function(
  BuildContext context,
  GoRouterState state,
);

/// the signature of the redirect builder callback for guarded routes
typedef GoRouteRedirectBuilder = String? Function(
  BuildContext context,
  GoRouterState state,
);

/// for route state during routing
class GoRouterState {
  final GoRouter router;
  final String location;
  final String pattern;
  final Map<String, String> args;
  final Exception? error;

  GoRouterState({
    required this.router,
    required this.location,
    this.pattern = '',
    this.args = const <String, String>{},
    this.error,
  });
}

/// a declarative mapping between a route name pattern and a route page builder
class GoRoute {
  /// the pattern in the form `/path/with/:var` interpretted using
  /// path_to_regexp package
  final String pattern;

  /// a function to create a page when the route pattern is matched
  final GoRouterPageBuilder builder;

  /// a function to create the list of page route builders for a given location
  final GoRouterRoutesBuilder? routes;

  /// ctor
  GoRoute({
    required this.pattern,
    required this.builder,
    this.routes,
  });
}

/// top-level go_router class; create one of these to initialize your app's
/// routing policy
class GoRouter {
  final _routeInformationParser = GoRouteInformationParser();
  late final GoRouterDelegate _routerDelegate;
  final _locPages = <String, Page<dynamic>>{};

  /// configure a GoRouter with a routes builder and an error page builder
  GoRouter({
    required GoRouterRoutesBuilder routes,
    required GoRouterPageBuilder error,
    GoRouteRedirectBuilder redirect = _noop,
    String initialLocation = '/',
    UrlPathStrategy? urlPathStrategy = UrlPathStrategy.hash,
  }) {
    if (urlPathStrategy != null) setUrlPathStrategy(urlPathStrategy);

    _routerDelegate = GoRouterDelegate(
      // wrap the returned Navigator to enable GoRouter.of(context).go()
      builder: (context, location) => InheritedGoRouter(
        goRouter: this,
        child: _builder(
          context: context,
          routes: routes(context, location),
          error: error,
          redirect: redirect,
          location: location,
        ),
      ),
      initialLocation: Uri.parse(initialLocation),
    );
  }

  static String? _noop(BuildContext context, GoRouterState state) => null;

  /// configure a GoRouter with a low-level builder
  GoRouter.builder({
    required GoRouterWidgetBuilder builder,
    String initialLocation = '/',
    UrlPathStrategy? urlPathStrategy,
  }) {
    if (urlPathStrategy != null) setUrlPathStrategy(urlPathStrategy);

    _routerDelegate = GoRouterDelegate(
      // wrap the returned Navigator to enable GoRouter.of(context).go()
      builder: (context, location) => InheritedGoRouter(
        goRouter: this,
        child: builder(context, location),
      ),
      initialLocation: Uri.parse(initialLocation),
    );
  }

  /// the RouteInformationParser associated with this GoRouter
  RouteInformationParser<Object> get routeInformationParser =>
      _routeInformationParser;

  /// the RouterDelegate associated with this GoRouter
  RouterDelegate<Object> get routerDelegate => _routerDelegate;

  /// get the current location
  String get location => _locPages.isEmpty ? '' : _locPages.keys.last;

  /// navigate to a URI location w/ optional query parameters, e.g.
  /// /family/f1/person/p2?color=blue
  void go(String location) => _routerDelegate.go(location);

  /// set the app's URL path strategy (defaults to hash). call before runApp().
  static void setUrlPathStrategy(UrlPathStrategy strategy) =>
      setUrlPathStrategyImpl(strategy);

  /// find the current GoRouter in the widget tree
  static GoRouter of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedGoRouter>()!.goRouter;

  Widget _builder({
    required BuildContext context,
    required Iterable<GoRoute> routes,
    required GoRouterPageBuilder error,
    required GoRouteRedirectBuilder redirect,
    required String location,
  }) {
    try {
      final locPages = _getLocPages(context, location, routes, redirect);
      // _goLocPages should ensure this
      assert(locPages.isNotEmpty);

      // if the single page on the stack is a redirect, then go there
      if (locPages.entries.first.value is GoRedirect) {
        // _goLocPages should ensure this
        assert(locPages.entries.length == 1);

        final redirect = locPages.entries.first.value as GoRedirect;
        if (_locationsMatch(redirect.location, location))
          throw Exception('redirecting to same location: $location');

        SchedulerBinding.instance?.addPostFrameCallback(
          (_) => _routerDelegate.go(redirect.location),
        );
      }
      // otherwise use this stack as is
      else {
        // _goLocPages should ensure this
        assert(locPages.entries.whereType<GoRedirect>().isEmpty);
        _locPages.clear();
        _locPages.addAll(locPages);
      }
    } on Exception catch (ex) {
      // if there's an error, show an error page
      _locPages.clear();
      _locPages[location] = error(
          context, GoRouterState(router: this, location: location, error: ex));
    }

    return Navigator(
      pages: _locPages.values.toList(),
      onPopPage: (route, dynamic result) {
        if (!route.didPop(result)) return false;

        // remove the route for the page we're showing and go to the next
        // location up
        assert(_locPages.isNotEmpty);
        _locPages.remove(_locPages.keys.last);
        _routerDelegate.go(_locPages.keys.last);

        return true;
      },
    );
  }

  Map<String, Page<dynamic>> _getLocPages(
    BuildContext context,
    String location,
    Iterable<GoRoute> routes,
    GoRouteRedirectBuilder redirect,
  ) {
    final locPages = <String, Page<dynamic>>{};
    for (final route in routes) {
      // pull the parameters out of the path of the location (w/o any query
      // parameters)
      final params = <String>[];
      final re = p2re.pathToRegExp(route.pattern,
          prefix: true, caseSensitive: false, parameters: params);
      final uri = Uri.parse(location);
      final match = re.matchAsPrefix(uri.path);
      if (match == null) continue;
      final args = p2re.extract(params, match);

      // add any query parameters but don't override existing positional params
      for (final param in uri.queryParameters.entries)
        if (!args.containsKey(param.key)) args[param.key] = param.value;

      // expand the route pattern with the current set of args to get location
      // for a future pop. get a redirect or page from the builder.
      final pageLoc = GoRouter._locationFor(route.pattern, args);
      final state = GoRouterState(
        router: this,
        location: location,
        pattern: route.pattern,
        args: args,
      );
      final redirectLoc = redirect(context, state);
      final page = redirectLoc == null || redirectLoc.isEmpty
          ? route.builder(context, state)
          : GoRedirect(redirectLoc);

      if (locPages.containsKey(pageLoc))
        throw Exception('duplicate location $pageLoc');
      locPages[pageLoc] = page;
    }

    // if the top location doesn't match the target location exactly, then we
    // haven't got a valid stack of pages; this allows '/' to match as part of a
    // stack of pages but to fail on '/nonsense'
    final topMatches =
        locPages.isNotEmpty && _locationsMatch(locPages.keys.last, location);
    if (!topMatches) throw Exception('page not found');

    // if the top page on the stack is a redirect, just return it
    if (locPages.entries.last.value is GoRedirect)
      return Map.fromEntries([locPages.entries.last]);

    // otherwise, ignore intermediate redirects and use this stack
    locPages.removeWhere((key, value) => value is GoRedirect);
    if (locPages.isEmpty) throw Exception('page not found');
    return locPages;
  }

  static bool _locationsMatch(String loc1, String loc2) {
    // check just the path w/o the queryParameters
    final uri1 = Uri.tryParse(loc1);
    final uri2 = Uri.tryParse(loc2);
    return uri1 != null &&
        uri2 != null &&
        uri1.path.toLowerCase().trim() == uri2.path.toLowerCase().trim();
  }

  static String _locationFor(String pattern, Map<String, String> args) =>
      p2re.pathToFunction(pattern)(args);
}

/// Dart extension to add the go() function to a BuildContext object, e.g.
/// context.go('/');
extension GoRouterHelper on BuildContext {
  void go(String location) => GoRouter.of(this).go(location);
}
