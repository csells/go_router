library go_router;

import 'package:flutter/widgets.dart';
import 'package:path_to_regexp/path_to_regexp.dart' as p2re;

import 'src/go_router_impl.dart';
import 'src/path_strategy_nonweb.dart'
    if (dart.library.html) 'src/path_strategy_web.dart';

/// for use in GoRouter.setUrlPathStrategy
enum UrlPathStrategy { hash, path }

/// the signature of the function to pass to the GoRouter.builder ctor
typedef GoRouterBuilder = Widget Function(
  BuildContext context,
  String location,
);

/// the signature of the page builder callback for a matched GoRoute
typedef GoRouterPageBuilder = Page<dynamic> Function(
  BuildContext context,
  GoRouterState state,
);

/// the signation of the redirect callback
typedef GoRouterRedirect = String? Function(String location);

/// for route state during routing
class GoRouterState {
  // the router associated with this state
  final GoRouter router;

  // the full location of the route, e.g. /family/f1/person/p2
  final String location;

  // the location to this sub-route, e.g. /family/f1
  final String subloc;

  // the path to this sub-route, e.g. family/:fid
  final String path;

  // the parameters for this sub-route, e.g. {'fid': 'f1'}
  final Map<String, String> params;

  // the unique key for this sub-route, e.g. ValueKey('/family/:fid')
  final ValueKey<String> pageKey;

  // the error associated with this sub-route
  final Exception? error;

  GoRouterState({
    required this.router,
    required this.location,
    required this.subloc,
    this.path = '',
    this.params = const <String, String>{},
    this.error,
    String fullpath = '',
  })  : assert(path.isEmpty == fullpath.isEmpty),
        pageKey = ValueKey(fullpath);
}

/// a declarative mapping between a route name path and a route page builder
class GoRoute {
  final _pathParams = <String>[];
  late final RegExp _pathRE;

  final String path;
  final GoRouterPageBuilder builder;
  final List<GoRoute>? routes;
  final GoRouterRedirect redirect;

  /// ctor
  GoRoute({
    required this.path,
    required this.builder,
    this.routes,
    this.redirect = _redirect,
  }) {
    // cache the path regexp and parameters
    _pathRE = p2re.pathToRegExp(
      path,
      prefix: true,
      caseSensitive: false,
      parameters: _pathParams,
    );

    // check stacked sub-route paths
    for (final route in routes ?? <GoRoute>[]) {
      if (route.path != '/' &&
          (route.path.startsWith('/') || route.path.endsWith('/'))) {
        throw Exception(
            'sub-route path may not start or end with /: ${route.path}');
      }
    }
  }

  Match? matchPatternAsPrefix(String loc) => _pathRE.matchAsPrefix(loc);
  Map<String, String> extractPatternParams(Match match) =>
      p2re.extract(_pathParams, match);

  static String? _redirect(String location) => null;
}

/// top-level go_router class; create one of these to initialize your app's
/// routing policy
class GoRouter {
  final routeInformationParser = GoRouteInformationParser();
  late final GoRouterDelegate routerDelegate;
  final GoRouterRedirect redirect;
  final _locPages = <String, Page<dynamic>>{};

  /// configure a GoRouter with a routes builder and an error page builder
  GoRouter({
    required Iterable<GoRoute> routes,
    required GoRouterPageBuilder error,
    this.redirect = _redirect,
    Listenable? refreshListenable,
    String initialLocation = '/',
    UrlPathStrategy? urlPathStrategy = UrlPathStrategy.hash,
  }) {
    _init(
      builder: (context, location) => _builder(
        context: context,
        routes: routes,
        error: error,
        location: location,
      ),
      initialLocation: initialLocation,
      urlPathStrategy: urlPathStrategy,
      refreshListenable: refreshListenable,
    );
  }

  /// configure a GoRouter with a widget builder
  GoRouter.builder({
    required GoRouterBuilder builder,
    this.redirect = _redirect,
    Listenable? refreshListenable,
    String initialLocation = '/',
    UrlPathStrategy? urlPathStrategy,
  }) {
    _init(
      builder: builder,
      initialLocation: initialLocation,
      urlPathStrategy: urlPathStrategy,
      refreshListenable: refreshListenable,
    );
  }

  void _init({
    required GoRouterBuilder builder,
    required String initialLocation,
    required UrlPathStrategy? urlPathStrategy,
    Listenable? refreshListenable,
  }) {
    if (urlPathStrategy != null) setUrlPathStrategy(urlPathStrategy);

    routerDelegate = GoRouterDelegate(
      // wrap the returned Navigator to enable GoRouter.of(context).go()
      builder: (context, location) => InheritedGoRouter(
        goRouter: this,
        child: builder(context, location),
      ),
      refreshListenable: refreshListenable,
      initialLocation: Uri.parse(initialLocation),
    );
  }

  /// get the current location
  String get location => _locPages.isEmpty ? '' : _locPages.keys.last;

  /// navigate to a URI location w/ optional query parameters, e.g.
  /// /family/f1/person/p2?color=blue
  void go(String location) => routerDelegate.go(location);

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
        GoRouterState(
          router: this,
          location: location,
          subloc: location,
          error: ex,
        ),
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
        routerDelegate.go(_locPages.keys.last);

        return true;
      },
    );
  }

  static String? _redirect(String location) => null;

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
      if (!route.path.startsWith('/')) {
        throw Exception(
            'top level route paths must start with /: ${route.path}');
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

      // merge new params, overriding old ones, i.e. path params override
      // query parameters, sub-location params override top level params, etc.
      // this also keeps params from previously matched paths, e.g.
      // /family/:fid/person/:pid provides fid and pid to person/:pid
      params = {...params, ...match.params};

      // get a page from the builder and associate it with a sub-location
      locPages[subloc.toString()] = match.route.builder(
        context,
        GoRouterState(
          router: this,
          location: location,
          subloc: subloc,
          path: match.route.path,
          fullpath: match.fullpath,
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

    final matchStacks = _getLocRouteMatchStacks(
      loc: loc,
      routes: routes,
      parentFullpath: '',
    );

    if (matchStacks.isEmpty) {
      throw Exception('no routes for location: $loc');
    }

    if (matchStacks.length > 1) {
      final sb = StringBuffer();
      sb.writeln('too many routes for location: $loc');

      for (final stack in matchStacks) {
        sb.writeln('\t${stack.map((m) => m.route.path).join(' => ')}');
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
  ///     match(route.path=/, loc=/)
  ///   ]
  /// ]
  ///
  /// loc: /login
  /// stacks: [
  ///   matches: [
  ///     match(route.path=/login, loc=login)
  ///   ]
  /// ]
  ///
  /// loc: /family/f2
  /// stacks: [
  ///   matches: [
  ///     match(route.path=/, loc=/),
  ///     match(route.path=family/:fid, loc=family/f2, params=[fid=f2])
  ///   ]
  /// ]
  ///
  /// loc: /family/f2/person/p1
  /// stacks: [
  ///   matches: [
  ///     match(route.path=/, loc=/),
  ///     match(route.path=family/:fid, loc=family/f2, params=[fid=f2])
  ///     match(route.path=person/:pid, loc=person/p1, params=[fid=f2, pid=p1])
  ///   ]
  /// ]
  ///
  /// A stack count of 0 means there's no match.
  /// A stack count of >1 means there's a malformed set of routes.
  ///
  /// NOTE: Uses recursion, which is why _getLocRouteMatchStacks calls this
  /// function and does the actual error checking, using the returned stacks to
  /// provide better errors
  static Iterable<List<GoRouteMatch>> _getLocRouteMatchStacks({
    required String loc,
    required Iterable<GoRoute> routes,
    required String parentFullpath,
  }) sync* {
    // find the set of matches at this level of the tree
    for (final route in routes) {
      final fullpath = _fullpathFor(parentFullpath, route.path);
      final match = GoRouteMatch.match(
        route: route,
        location: loc,
        fullpath: fullpath,
      );
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
      final subRouteMatchStacks = _getLocRouteMatchStacks(
        loc: rest,
        routes: route.routes!,
        parentFullpath: fullpath,
      ).toList();
      if (subRouteMatchStacks.isEmpty) continue;

      // add the match to each of the sub-route match stacks and return them
      for (final stack in subRouteMatchStacks) yield [match, ...stack];
    }
  }

  static String _fullpathFor(String parentFullpath, String path) {
    // at the root, just return the path
    if (parentFullpath.isEmpty) {
      assert(path.startsWith('/'));
      assert(path == '/' || !path.endsWith('/'));
      return path;
    }

    // not at the root, so append the parent path
    assert(path.isNotEmpty);
    assert(!path.startsWith('/'));
    assert(!path.endsWith('/'));
    return '${parentFullpath == '/' ? '' : parentFullpath}/$path';
  }

  static String locationFor(String path, Map<String, String> params) =>
      p2re.pathToFunction(path)(params);
}

/// Dart extension to add the go() function to a BuildContext object, e.g.
/// context.go('/');
extension GoRouterHelper on BuildContext {
  void go(String location) => GoRouter.of(this).go(location);
}
