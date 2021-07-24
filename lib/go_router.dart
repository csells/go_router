library go_router;

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
abstract class GoRouterGuard extends ChangeNotifier {
  final Listenable? listenable;
  GoRouterGuard([this.listenable]) {
    listenable?.addListener(notifyListeners);
  }

  @override
  void dispose() {
    listenable?.removeListener(notifyListeners);
    super.dispose();
  }

  /// called to see if a location should be redirected
  String? redirect(String location);
}

/// for route state during routing
class GoRouterState {
  final GoRouter router;
  final String location;
  final String pattern;
  final Map<String, String> params;
  final Exception? error;

  GoRouterState({
    required this.router,
    required this.location,
    this.pattern = '',
    this.params = const <String, String>{},
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
  final List<GoRoute>? routes;

  final _patterParams = <String>[];
  late final RegExp _patternRE;

  /// ctor
  GoRoute({
    required this.pattern,
    required this.builder,
    this.routes,
  }) {
    // cache the pattern regexp and parameters
    _patternRE = p2re.pathToRegExp(
      pattern,
      prefix: true,
      caseSensitive: false,
      parameters: _patterParams,
    );

    // check sub-route patterns
    for (final route in routes ?? <GoRoute>[]) {
      if (route.pattern != '/' &&
          (route.pattern.startsWith('/') || route.pattern.endsWith('/'))) {
        throw Exception(
            'sub-route pattern may not start or end with /: ${route.pattern}');
      }
    }
  }

  Match? matchPatternAsPrefix(String loc) => _patternRE.matchAsPrefix(loc);
  Map<String, String> extractPatternParams(Match match) =>
      p2re.extract(_patterParams, match);
}

/// top-level go_router class; create one of these to initialize your app's
/// routing policy
class GoRouter {
  final _routeInformationParser = GoRouteInformationParser();
  late final GoRouterDelegate _routerDelegate;
  final _locPages = <String, Page<dynamic>>{};

  /// configure a GoRouter with a routes builder and an error page builder
  GoRouter({
    /// a function to create the list of page route builders for a given
    /// location
    required GoRouterRoutesBuilder routes,

    /// a function to create the error page for a given location
    required GoRouterPageBuilder error,

    /// an object to create the redirect for a given location
    GoRouterGuard? guard,

    /// the initial location to use for routing
    String initialLocation = '/',

    /// the URL path strategy to use for routing
    UrlPathStrategy? urlPathStrategy = UrlPathStrategy.hash,
  }) {
    _init(
      builder: (context, location) => _builder(
        context: context,
        routes: routes(context, location),
        error: error,
        location: location,
      ),
      initialLocation: initialLocation,
      urlPathStrategy: urlPathStrategy,
      guard: guard,
    );
  }

  /// configure a GoRouter with a widget builder
  GoRouter.builder({
    required GoRouterWidgetBuilder builder,
    String initialLocation = '/',
    UrlPathStrategy? urlPathStrategy,
  }) {
    _init(
      builder: builder,
      initialLocation: initialLocation,
      urlPathStrategy: urlPathStrategy,
    );
  }

  void _init({
    required GoRouterWidgetBuilder builder,
    required String initialLocation,
    required UrlPathStrategy? urlPathStrategy,
    GoRouterGuard? guard,
  }) {
    if (urlPathStrategy != null) setUrlPathStrategy(urlPathStrategy);

    _routerDelegate = GoRouterDelegate(
      // wrap the returned Navigator to enable GoRouter.of(context).go()
      builder: (context, location) => InheritedGoRouter(
        goRouter: this,
        child: builder(context, location),
      ),
      guard: guard,
      initialLocation: Uri.parse(initialLocation),
    );
  }

  /// the RouteInformationParser associated with this GoRouter
  GoRouteInformationParser get routeInformationParser =>
      _routeInformationParser;

  /// the RouterDelegate associated with this GoRouter
  GoRouterDelegate get routerDelegate => _routerDelegate;

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
    required String location,
  }) {
    try {
      // build the stack of pages
      final locPages = getLocPages(context, location, routes);
      assert(locPages.isNotEmpty);
      _locPages.clear();
      _locPages.addAll(locPages);
    } on Exception catch (ex) {
      // if there's an error, show an error page
      _locPages.clear();
      _locPages[location] = error(
        context,
        GoRouterState(router: this, location: location, error: ex),
      );
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

  /// get the stack of routes that matches the location and turn it into a stack
  /// of sub-location, page pairs
  /// e.g. routes: [
  ///   /
  ///     family/:fid
  ///   /login
  /// ]
  ///
  /// loc: /
  /// pairs: [
  ///   / => HomePage()
  /// ]
  ///
  /// loc: /login
  /// pairs: [
  ///   /login => LoginPage()
  /// ]
  ///
  /// loc: /family/f2
  /// pairs: [
  ///   / => HomePage()
  ///   /family/f2 => FamilyPage(f2)
  /// ]
  ///
  /// loc: /family/f2/person/p1
  /// pairs: [
  ///   / => HomePage()
  ///   /family/f2 => FamilyPage(f2)
  ///   /family/f2/person/p1 => PersonPage(f2, p1)
  /// ]
  @visibleForTesting
  Map<String, Page<dynamic>> getLocPages(
    BuildContext context,
    String location,
    Iterable<GoRoute> routes,
  ) {
    // check all of the top level routes
    for (final route in routes) {
      if (!route.pattern.startsWith('/')) {
        throw Exception(
            'top level route patterns must start with /: ${route.pattern}');
      }
    }

    final uri = Uri.parse(location);
    final matchStack = _getLocRouteMatchStack(uri.path, routes);
    assert(matchStack.isNotEmpty);

    final locPages = <String, Page<dynamic>>{};
    var subloc = ''; // start w/ an empty sub-location
    var params = uri.queryParameters; // start w/ the query parameters
    for (final match in matchStack) {
      // append each sub-location, e.g. / + family/:fid + person/:pid
      // ignore: use_string_buffers
      subloc = subloc +
          (subloc.endsWith('/') || match.loc.startsWith('/') ? '' : '/') +
          match.loc;

      // merge new params, overriding old ones, i.e. pattern params override
      // query parameters, sub-location params override top level params, etc.
      // this also keeps params from previously matched patterns, e.g.
      // /family/:fid/person/:pid provides fid and pid to person/:pid
      params = {...params, ...match.params};

      // get a page from the builder and associate it with a sub-location
      locPages[subloc.toString()] = match.route.builder(
        context,
        GoRouterState(
          router: this,
          location: location,
          pattern: match.route.pattern,
          params: params,
        ),
      );
    }

    assert(locPages.isNotEmpty);
    return locPages;
  }

  /// Call _getLocRouteMatchStacks and check for errors
  static List<GoRouteMatch> _getLocRouteMatchStack(
    String loc,
    Iterable<GoRoute> routes,
  ) {
    // assume somebody else has removed the query params
    assert(Uri.parse(loc).path == loc);

    final matchStacks = _getLocRouteMatchStacks(loc, routes);
    if (matchStacks.isEmpty) {
      throw Exception('no routes for location: $loc');
    }

    if (matchStacks.length > 1) {
      final sb = StringBuffer();
      sb.writeln('too many routes for location: $loc');

      for (final stack in matchStacks) {
        sb.writeln('\t${stack.map((m) => m.route.pattern).join(' => ')}');
      }

      throw Exception(sb.toString());
    }

    assert(matchStacks.length == 1);
    return matchStacks.first;
  }

  /// turns a list of routes into a list of routes match stacks for the location
  /// e.g. routes: [
  ///   /
  ///     family/:fid
  ///   /login
  /// ]
  ///
  /// loc: /
  /// stacks: [
  ///   matches: [
  ///     match(route.pattern=/, loc=/)
  ///   ]
  /// ]
  ///
  /// loc: /login
  /// stacks: [
  ///   matches: [
  ///     match(route.pattern=/login, loc=login)
  ///   ]
  /// ]
  ///
  /// loc: /family/f2
  /// stacks: [
  ///   matches: [
  ///     match(route.pattern=/, loc=/),
  ///     match(route.pattern=family/:fid, loc=family/f2, params=[fid=f2])
  ///   ]
  /// ]
  ///
  /// loc: /family/f2/person/p1
  /// stacks: [
  ///   matches: [
  ///     match(route.pattern=/, loc=/),
  ///     match(route.pattern=family/:fid, loc=family/f2, params=[fid=f2])
  ///     match(route.pattern=person/:pid, loc=person/p1, params=[fid=f2, pid=p1])
  ///   ]
  /// ]
  ///
  /// A stack count of 0 means there's no match.
  /// A stack count of >1 means there's a malformed set of routes.
  ///
  /// NOTE: Uses recursion, which is why _getLocRouteMatchStacks calls this
  /// function and does the actual error checking, using the returned stacks to
  /// provide better errors
  static Iterable<List<GoRouteMatch>> _getLocRouteMatchStacks(
    String loc,
    Iterable<GoRoute> routes,
  ) sync* {
    // find the set of matches at this level of the tree
    for (final route in routes) {
      final match = GoRouteMatch.match(route, loc);
      if (match == null) continue;

      // if we have a complete match, then return the matched route
      if (match.loc == loc) {
        yield [match];
        continue;
      }

      // if we have a partial match but no sub-routes, bail
      if (route.routes == null) continue;

      // otherwise recurse
      final rest = loc.substring(match.loc.length + (match.loc == '/' ? 0 : 1));
      assert(loc.startsWith(match.loc));
      assert(rest.isNotEmpty);

      // if there's no sub-route matches, then we don't have a match for this
      // location
      final subRouteMatchStacks =
          _getLocRouteMatchStacks(rest, route.routes!).toList();
      if (subRouteMatchStacks.isEmpty) continue;

      // add the match to each of the sub-route match stacks and return them
      for (final stack in subRouteMatchStacks) yield [match, ...stack];
    }
  }

  static String locationFor(String pattern, Map<String, String> args) =>
      p2re.pathToFunction(pattern)(args);
}

/// Dart extension to add the go() function to a BuildContext object, e.g.
/// context.go('/');
extension GoRouterHelper on BuildContext {
  void go(String location) => GoRouter.of(this).go(location);
}
