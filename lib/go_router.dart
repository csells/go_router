library go_router;

import 'package:flutter/widgets.dart';
import 'package:path_to_regexp/path_to_regexp.dart' as p2re;

import 'src/go_router_impl.dart';
import 'src/path_strategy_nonweb.dart'
    if (dart.library.html) 'src/path_strategy_web.dart';

/// for use in GoRouter.setUrlPathStrategy
enum UrlPathStrategy { hash, path }

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

  // the location of this sub-route, e.g. /family/f1
  final String subloc;

  // the path to this sub-route, e.g. family/:fid
  final String path;

  // the full path to this sub-route, e.g. /family/:fid
  final String fullpath;

  // the parameters for this sub-route, e.g. {'fid': 'f1'}
  final Map<String, String> params;

  // the error associated with this sub-route
  final Exception? error;

  GoRouterState({
    required this.router,
    required this.location,
    required this.subloc,
    this.path = '',
    this.fullpath = '',
    this.params = const <String, String>{},
    this.error,
  }) : assert(path.isEmpty == fullpath.isEmpty);

  // the unique key for this sub-route, e.g. ValueKey('/family/:fid')
  ValueKey<String> get pageKey => ValueKey(fullpath);
}

/// a declarative mapping between a route path and a route page builder
class GoRoute {
  final _pathParams = <String>[];
  late final RegExp _pathRE;

  final String path;
  final GoRouterPageBuilder builder;
  final List<GoRoute> routes;
  final GoRouterRedirect redirect;

  /// ctor
  GoRoute({
    required this.path,
    this.builder = _builder,
    this.routes = const [],
    this.redirect = _redirect,
  }) {
    // cache the path regexp and parameters
    _pathRE = p2re.pathToRegExp(
      path,
      prefix: true,
      caseSensitive: false,
      parameters: _pathParams,
    );

    // check sub-route paths
    for (final route in routes) {
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
  static Page<dynamic> _builder(BuildContext context, GoRouterState state) =>
      throw Exception('GoRoute builder parameter not set');
}

/// top-level go_router class; create one of these to initialize your app's
/// routing policy
class GoRouter {
  final routeInformationParser = GoRouteInformationParser();
  late final GoRouterDelegate routerDelegate;
  final GoRouterRedirect redirect;
  final GoRouterPageBuilder error;

  /// configure a GoRouter with a routes builder and an error page builder
  GoRouter({
    required List<GoRoute> routes,
    required this.error,
    this.redirect = _redirect,
    Listenable? refreshListenable,
    String initialLocation = '/',
    UrlPathStrategy? urlPathStrategy = UrlPathStrategy.hash,
    bool debugOutputFullPaths = false,
  }) {
    if (urlPathStrategy != null) setUrlPathStrategy(urlPathStrategy);

    routerDelegate = GoRouterDelegate(
      // wrap the returned Navigator to enable GoRouter.of(context).go()
      builder: (context, matches) => InheritedGoRouter(
        goRouter: this,
        child: _builder(context: context, matches: matches),
      ),
      routes: routes,
      topRedirect: redirect,
      refreshListenable: refreshListenable,
      initUri: Uri.parse(initialLocation),
      debugOutputFullPaths: debugOutputFullPaths,
    );
  }

  /// get the current location
  String get location => routerDelegate.currentConfiguration.toString();

  /// navigate to a URI location w/ optional query parameters, e.g.
  /// /family/f1/person/p2?color=blue
  void go(String location) => routerDelegate.go(location);

  /// refresh the route
  void refresh() => routerDelegate.refresh();

  /// set the app's URL path strategy (defaults to hash). call before runApp().
  static void setUrlPathStrategy(UrlPathStrategy strategy) =>
      setUrlPathStrategyImpl(strategy);

  /// find the current GoRouter in the widget tree
  static GoRouter of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedGoRouter>()!.goRouter;

  /// expand a path w/ param slots using params, e.g. family/:fid => family/f1
  static String locationFor(String path, Map<String, String> params) =>
      p2re.pathToFunction(path)(params);

  Widget _builder({
    required BuildContext context,
    required Iterable<GoRouteMatch> matches,
  }) {
    final pages = <Page<dynamic>>[];

    try {
      // build the stack of pages
      final routePages = getPages(context, matches);
      pages.addAll(routePages);
    } on Exception catch (ex) {
      // if there's an error, show an error page
      final errorPage = error(
        context,
        GoRouterState(
          router: this,
          location: location,
          subloc: location,
          error: ex,
        ),
      );
      pages.add(errorPage);
    }

    return Navigator(
      pages: pages,
      onPopPage: (route, dynamic result) {
        if (!route.didPop(result)) return false;
        routerDelegate.pop();
        return true;
      },
    );
  }

  static String? _redirect(String location) => null;

  /// get the stack of sub-routes that matches the location and turn it into a
  /// stack of pages, e.g.
  /// routes: [
  ///   /
  ///     family/:fid
  ///       person/:pid
  ///   /login
  /// ]
  ///
  /// loc: /
  /// pages: [ HomePage()]
  ///
  /// loc: /login
  /// pages: [ LoginPage() ]
  ///
  /// loc: /family/f2
  /// pages: [  HomePage(), FamilyPage(f2) ]
  ///
  /// loc: /family/f2/person/p1
  /// pages: [ HomePage(), FamilyPage(f2), PersonPage(f2, p1) ]
  @visibleForTesting
  List<Page<dynamic>> getPages(
    BuildContext context,
    Iterable<GoRouteMatch> matches,
  ) {
    final pages = <Page<dynamic>>[];
    final uri = Uri.parse(matches.last.subloc);
    var params = uri.queryParameters; // start w/ the query parameters
    for (final match in matches) {
      // merge new params, overriding old ones, i.e. path params override
      // query parameters, sub-location params override top level params, etc.
      // this also keeps params from previously matched paths, e.g.
      // /family/:fid/person/:pid provides fid and pid to person/:pid
      params = {...params, ...match.params};

      // get a page from the builder and associate it with a sub-location
      final page = match.route.builder(
        context,
        GoRouterState(
          router: this,
          location: location,
          subloc: match.subloc,
          path: match.route.path,
          fullpath: match.fullpath,
          params: params,
        ),
      );
      pages.add(page);
    }

    assert(pages.isNotEmpty);
    return pages;
  }
}

/// Dart extension to add the go() function to a BuildContext object, e.g.
/// context.go('/');
extension GoRouterHelper on BuildContext {
  void go(String location) => GoRouter.of(this).go(location);
}
