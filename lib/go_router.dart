library go_router;

import 'package:collection/collection.dart';
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
typedef GoRouterRedirect = String? Function(GoRouterState state);

/// for route state during routing
class GoRouterState {
  // the full location of the route, e.g. /family/f1/person/p2
  final String location;

  // the location of this sub-route, e.g. /family/f1
  final String subloc;

  // the path to this sub-route, e.g. family/:fid
  final String? path;

  // the full path to this sub-route, e.g. /family/:fid
  final String? fullpath;

  // the parameters for this sub-route, e.g. {'fid': 'f1'}
  final Map<String, String> params;

  // the error associated with this sub-route
  final Exception? error;

  // the unique key for this sub-route, e.g. ValueKey('/family/:fid')
  ValueKey<String> get pageKey => ValueKey(error != null ? 'error' : fullpath!);

  GoRouterState({
    required this.location,
    required this.subloc,
    this.path,
    this.fullpath,
    this.params = const <String, String>{},
    this.error,
  }) : assert((path ?? '').isEmpty == (fullpath ?? '').isEmpty);
}

/// a declarative mapping between a route path and a page builder
class GoRoute {
  final _pathParams = <String>[];
  late final RegExp _pathRE;

  final String? name;
  final String path;
  final GoRouterPageBuilder builder;
  final List<GoRoute> routes;
  final GoRouterRedirect redirect;

  /// ctor
  GoRoute({
    required this.path,
    this.name,
    this.builder = _builder,
    this.routes = const [],
    this.redirect = _redirect,
  }) {
    if (path.isEmpty) {
      throw Exception('GoRoute path cannot be empty');
    }

    if (name != null && name!.isEmpty) {
      throw Exception('GoRoute name cannot be empty');
    }

    // cache the path regexp and parameters
    _pathRE = p2re.pathToRegExp(
      path,
      prefix: true,
      caseSensitive: false,
      parameters: _pathParams,
    );

    // check path params
    final paramNames = <String>[];
    p2re.parse(path, parameters: paramNames);
    final groupedParams = paramNames.groupListsBy((p) => p);
    final dupParams = Map<String, List<String>>.fromEntries(
      groupedParams.entries.where((e) => e.value.length > 1),
    );
    if (dupParams.isNotEmpty) {
      throw Exception('duplicate path params: ${dupParams.keys.join(', ')}');
    }

    // check sub-routes
    for (final route in routes) {
      // check paths
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

  static String? _redirect(GoRouterState state) => null;
  static Page<dynamic> _builder(BuildContext context, GoRouterState state) =>
      throw Exception('GoRoute builder parameter not set');
}

/// top-level go_router class; create one of these to initialize your app's
/// routing policy
class GoRouter extends ChangeNotifier {
  final routeInformationParser = GoRouteInformationParser();
  late final GoRouterDelegate routerDelegate;

  /// configure a GoRouter with a routes builder and an error page builder
  GoRouter({
    required List<GoRoute> routes,
    required GoRouterPageBuilder error,
    GoRouterRedirect? redirect,
    Listenable? refreshListenable,
    String initialLocation = '/',
    UrlPathStrategy? urlPathStrategy = UrlPathStrategy.hash,
    bool debugLogDiagnostics = false,
  }) {
    if (urlPathStrategy != null) setUrlPathStrategy(urlPathStrategy);

    routerDelegate = GoRouterDelegate(
      routes: routes,
      errorBuilder: error,
      topRedirect: redirect ?? (_) => null,
      refreshListenable: refreshListenable,
      initUri: Uri.parse(initialLocation),
      onLocationChanged: notifyListeners,
      debugLogDiagnostics: debugLogDiagnostics,
      // wrap the returned Navigator to enable GoRouter.of(context).go() et al
      builderWithNav: (context, nav) =>
          InheritedGoRouter(goRouter: this, child: nav),
    );
  }

  /// get the current location
  String get location => routerDelegate.currentConfiguration.toString();

  /// navigate to a URI location w/ optional query parameters, e.g.
  /// /family/f2/person/p1?color=blue
  void go(String location) => routerDelegate.go(location);

  /// navigate to a named route w/ optional parameters, e.g.
  /// name='person', params={'fid': 'f2', 'pid': 'p1'}
  void goNamed(String name, [Map<String, String> params = const {}]) =>
      routerDelegate.goNamed(name, params);

  /// refresh the route
  void refresh() => routerDelegate.refresh();

  /// set the app's URL path strategy (defaults to hash). call before runApp().
  static void setUrlPathStrategy(UrlPathStrategy strategy) =>
      setUrlPathStrategyImpl(strategy);

  /// find the current GoRouter in the widget tree
  static GoRouter of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedGoRouter>()!.goRouter;
}

/// Dart extension to add the go() function to a BuildContext object, e.g.
/// context.go('/');
extension GoRouterHelper on BuildContext {
  void go(String location) => GoRouter.of(this).go(location);
  void goNamed(String name, [Map<String, String> params = const {}]) =>
      GoRouter.of(this).goNamed(name, params);
}
