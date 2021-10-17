import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_to_regexp/path_to_regexp.dart' as p2re;

import '../go_router.dart';

const _debugLog2Diagnostics = false;
// const _debugLog2Diagnostics = kDebugMode;

void _log2(String s) {
  if (_debugLog2Diagnostics) debugPrint('  $s');
}

/// Signature of a go router builder function with matchers.
typedef GoRouterBuilderWithMatches = Widget Function(
  BuildContext context,
  Iterable<GoRouteMatch> matches,
);

/// Signature of a go router builder function with navigator.
typedef GoRouterBuilderWithNav = Widget Function(
  BuildContext context,
  Navigator navigator,
);

/// GoRouter implementation of the RouterDelegate base class.
class GoRouterDelegate extends RouterDelegate<Uri>
    with
        PopNavigatorRouterDelegateMixin<Uri>,
        // ignore: prefer_mixin
        ChangeNotifier {
  /// Constructor for GoRouter's implementation of the
  /// RouterDelegate base class.
  GoRouterDelegate({
    required this.builderWithNav,
    required this.routes,
    required this.errorPageBuilder,
    required this.topRedirect,
    required this.redirectLimit,
    required this.refreshListenable,
    required Uri initUri,
    required this.observers,
    required this.debugLogDiagnostics,
    this.restorationScopeId,
  }) {
    // check top-level route paths are valid
    for (final route in routes) {
      if (!route.path.startsWith('/')) {
        throw Exception('top-level path must start with "/": ${route.path}');
      }
    }

    // cache the set of named routes for fast lookup
    _cacheNamedRoutes(routes, '', _namedMatches);

    // output known routes
    _outputKnownRoutes();

    // build the list of route matches
    _log('setting initial location $initUri');
    _go(initUri.toString());

    // when the listener changes, refresh the route
    refreshListenable?.addListener(refresh);
  }

  /// Builder function for a go router with Navigator.
  final GoRouterBuilderWithNav builderWithNav;

  /// List of top level routes used by the go router delegate.
  final List<GoRoute> routes;

  /// Error page builder for the go router delegate.
  final GoRouterPageBuilder errorPageBuilder;

  /// Top level page redirect.
  final GoRouterRedirect topRedirect;

  /// The limit for the number of consecutive redirects.
  final int redirectLimit;

  /// Listenable used to cause the router to refresh it's route.
  final Listenable? refreshListenable;

  /// NavigatorObserver used to receive change notifications when
  /// navigation changes.
  final List<NavigatorObserver> observers;

  /// Set to true to log diagnostic info for your routes.
  final bool debugLogDiagnostics;

  /// Restoration ID to save and restore the state of the navigator, including its history.
  final String? restorationScopeId;

  final _key = GlobalKey<NavigatorState>();
  final List<GoRouteMatch> _matches = [];
  final _namedMatches = <String, GoRouteMatch>{};
  final _pushCounts = <String, int>{};

  void _cacheNamedRoutes(
    List<GoRoute> routes,
    String parentFullpath,
    Map<String, GoRouteMatch> namedFullpaths,
  ) {
    for (final route in routes) {
      final fullpath = _fullLocFor(parentFullpath, route.path);

      if (route.name != null) {
        final name = route.name!.toLowerCase();
        if (namedFullpaths.containsKey(name)) {
          throw Exception('duplication fullpaths for name "$name":'
              '${namedFullpaths[name]!.fullpath}, $fullpath');
        }

        // we only have a partial match until we have a location;
        // we're really only caching the route and fullpath at this point
        final match = GoRouteMatch(
          route: route,
          subloc: '/TBD',
          fullpath: fullpath,
          params: {},
          queryParams: {},
          extra: null,
        );

        namedFullpaths[name] = match;
      }

      if (route.routes.isNotEmpty)
        _cacheNamedRoutes(route.routes, fullpath, namedFullpaths);
    }
  }

  /// Get a location from route name and parameters.
  /// This is useful for redirecting to a named location.
  String namedLocation(
    String name, {
    required Map<String, String> params,
    required Map<String, String> queryParams,
  }) {
    _log('getting location for name: '
        '"$name"'
        '${params.isEmpty ? '' : ', params: $params'}'
        '${queryParams.isEmpty ? '' : ', queryParams: $queryParams'}');

    // find route and build up the full path along the way
    final match = _getNameRouteMatch(
      name,
      params: params,
      queryParams: queryParams,
    );
    if (match == null) throw Exception('unknown route name: $name');

    assert(identical(match.queryParams, queryParams));
    return _addQueryParams(match.subloc, queryParams);
  }

  /// Navigate to the given location.
  void go(String location, {Object? extra}) {
    _log('going to $location');
    _go(location, extra: extra);
    _safeNotifyListeners();
  }

  /// push the given location onto the page stack
  void push(String location, {Object? extra}) {
    _log('pushing $location');
    _push(location, extra: extra);
    _safeNotifyListeners();
  }

  /// Refresh the current location, including re-evaluating redirections.
  void refresh() {
    _log('refreshing $location');
    _go(location, extra: _matches.last.extra);
    _safeNotifyListeners();
  }

  /// Get the current location, e.g. /family/f2/person/p1
  String get location =>
      _addQueryParams(_matches.last.subloc, _matches.last.queryParams);

  /// For internal use; visible for testing only.
  @visibleForTesting
  List<GoRouteMatch> get matches => _matches;

  /// Dispose resources held by the router delegate.
  @override
  void dispose() {
    refreshListenable?.removeListener(refresh);
    super.dispose();
  }

  /// For use by the Router architecture as part of the RouterDelegate.
  @override
  GlobalKey<NavigatorState> get navigatorKey => _key;

  /// For use by the Router architecture as part of the RouterDelegate.
  @override
  Uri get currentConfiguration {
    _log2('GoRouterDelegate.currentConfiguration: $location');
    return Uri.parse(location);
  }

  /// For use by the Router architecture as part of the RouterDelegate.
  @override
  Widget build(BuildContext context) {
    _log2('GoRouterDelegate.build: matches=');
    for (final match in matches) _log2('  $match');
    return _builder(context, _matches);
  }

  /// For use by the Router architecture as part of the RouterDelegate.
  @override
  Future<void> setInitialRoutePath(Uri configuration) async {
    _log2(
        'GoRouterDelegate.setInitialRoutePath: configuration= $configuration');

    // if the initial location is /, then use the dev initial location;
    // otherwise, we're cruising to a deep link, so ignore dev initial location
    final config = configuration.toString();
    if (config == '/') {
      _go(location);
    } else {
      _log('deep linking to $config');
      _go(config);
    }
  }

  /// For use by the Router architecture as part of the RouterDelegate.
  @override
  Future<void> setNewRoutePath(Uri configuration) async {
    _log2('GoRouterDelegate.setNewRoutePath: configuration= $configuration');
    final config = configuration.toString();
    _log('going to $config');
    _go(config);
  }

  void _log(Object o) {
    if (debugLogDiagnostics) debugPrint('GoRouter: $o');
  }

  void _go(String location, {Object? extra}) {
    final matches = _getLocRouteMatchesWithRedirects(location, extra: extra);
    assert(matches.isNotEmpty);

    // replace the stack of matches w/ the new ones
    _matches.clear();
    _matches.addAll(matches);
  }

  void _push(String location, {Object? extra}) {
    final matches = _getLocRouteMatchesWithRedirects(location, extra: extra);
    assert(matches.isNotEmpty);
    final top = matches.last;

    // remap the pageKey so allow any number of the same page on the stack
    final fullpath = top.fullpath;
    final count = (_pushCounts[fullpath] ?? 0) + 1;
    _pushCounts[fullpath] = count;
    final pageKey = ValueKey('$fullpath-p$count');
    final match = GoRouteMatch(
      route: top.route,
      subloc: top.subloc,
      fullpath: top.fullpath,
      params: top.params,
      queryParams: top.queryParams,
      extra: extra,
      pageKey: pageKey,
    );

    // add a new match onto the stack of matches
    assert(matches.isNotEmpty);
    _matches.add(match);
  }

  List<GoRouteMatch> _getLocRouteMatchesWithRedirects(
    String location, {
    required Object? extra,
  }) {
    // start redirecting from the initial location
    List<GoRouteMatch> matches;

    try {
      // watch redirects for loops
      final redirects = [_canonicalUri(location)];
      bool redirected(String? redir) {
        if (redir == null) return false;

        if (Uri.tryParse(redir) == null) {
          throw Exception('invalid redirect: $redir');
        }

        if (redirects.contains(redir)) {
          redirects.add(redir);
          final msg = 'redirect loop detected: ${redirects.join(' => ')}';
          throw Exception(msg);
        }

        redirects.add(redir);
        if (redirects.length - 1 > redirectLimit) {
          final msg = 'too many redirects: ${redirects.join(' => ')}';
          throw Exception(msg);
        }

        _log('redirecting to $redir');
        return true;
      }

      // keep looping till we're done redirecting
      for (;;) {
        final loc = redirects.last;

        // check for top-level redirect
        final uri = Uri.parse(loc);
        if (redirected(
          topRedirect(
            GoRouterState(
              this,
              location: loc,
              name: null,
              // trim the query params off the subloc to match route.redirect
              subloc: uri.path,
              // pass along the query params 'cuz that's all we have right now
              queryParams: uri.queryParameters,
            ),
          ),
        )) continue;

        // get stack of route matches
        matches = _getLocRouteMatches(loc, extra: extra);

        // check top route for redirect
        final top = matches.last;
        if (redirected(
          top.route.redirect(
            GoRouterState(
              this,
              location: loc,
              subloc: top.subloc,
              name: top.route.name,
              path: top.route.path,
              fullpath: top.fullpath,
              params: top.params,
              queryParams: top.queryParams,
              extra: extra,
            ),
          ),
        )) continue;

        // let Router know to update the address bar
        if (redirects.length > 1) // the initial route is not a redirect
          _safeNotifyListeners();

        // no more redirects!
        break;
      }
    } on Exception catch (ex) {
      _log(ex.toString());

      // create a match that routes to the error page
      final uri = Uri.parse(location);
      matches = [
        GoRouteMatch(
          subloc: uri.path,
          fullpath: uri.path,
          params: {},
          queryParams: uri.queryParameters,
          extra: null,
          route: GoRoute(
            path: location,
            pageBuilder: (context, state) => errorPageBuilder(
              context,
              GoRouterState(
                this,
                location: state.location,
                subloc: state.subloc,
                name: state.name,
                path: state.path,
                error: ex,
                fullpath: state.path,
                params: state.params,
                queryParams: state.queryParams,
                extra: state.extra,
              ),
            ),
          ),
        ),
      ];
    }

    assert(matches.isNotEmpty);
    return matches;
  }

  List<GoRouteMatch> _getLocRouteMatches(
    String location, {
    Object? extra,
  }) {
    final uri = Uri.parse(location);
    final matchStacks = _getLocRouteMatchStacks(
      loc: uri.path,
      restLoc: uri.path,
      routes: routes,
      parentFullpath: '',
      parentSubloc: '',
      queryParams: uri.queryParameters,
      extra: extra,
    ).toList();

    if (matchStacks.isEmpty) {
      throw Exception('no routes for location: $location');
    }

    if (matchStacks.length > 1) {
      final sb = StringBuffer();
      sb.writeln('too many routes for location: $location');

      for (final stack in matchStacks) {
        sb.writeln('\t${stack.map((m) => m.route.path).join(' => ')}');
      }

      throw Exception(sb.toString());
    }

    if (kDebugMode) {
      assert(matchStacks.length == 1);
      final match = matchStacks.first.last;
      final loc1 = _addQueryParams(match.subloc, match.queryParams);
      final loc2 = _canonicalUri(location);

      // NOTE: match the lower case, since subloc is canonicalized to match the
      // path case whereas the location can be any case
      assert(loc1.toLowerCase() == loc2.toLowerCase(), '$loc1 != $loc2');
    }

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
    required String restLoc,
    required String parentSubloc,
    required List<GoRoute> routes,
    required String parentFullpath,
    required Map<String, String> queryParams,
    required Object? extra,
  }) sync* {
    // find the set of matches at this level of the tree
    for (final route in routes) {
      final fullpath = _fullLocFor(parentFullpath, route.path);
      final match = GoRouteMatch._match(
        route: route,
        restLoc: restLoc,
        parentSubloc: parentSubloc,
        path: route.path,
        fullpath: fullpath,
        queryParams: queryParams,
        extra: extra,
      );
      if (match == null) continue;

      // if we have a complete match, then return the matched route
      // NOTE: need a lower case match because subloc is canonicalized to match
      // the path case whereas the location can be of any case and still match
      if (match.subloc.toLowerCase() == loc.toLowerCase()) {
        yield [match];
        continue;
      }

      // if we have a partial match but no sub-routes, bail
      if (route.routes.isEmpty) continue;

      // otherwise recurse
      final childRestLoc =
          loc.substring(match.subloc.length + (match.subloc == '/' ? 0 : 1));
      assert(loc.startsWith(match.subloc));
      assert(restLoc.isNotEmpty);

      // if there's no sub-route matches, then we don't have a match for this
      // location
      final subRouteMatchStacks = _getLocRouteMatchStacks(
        loc: loc,
        restLoc: childRestLoc,
        parentSubloc: match.subloc,
        routes: route.routes,
        parentFullpath: fullpath,
        queryParams: queryParams,
        extra: extra,
      ).toList();
      if (subRouteMatchStacks.isEmpty) continue;

      // add the match to each of the sub-route match stacks and return them
      for (final stack in subRouteMatchStacks) yield [match, ...stack];
    }
  }

  GoRouteMatch? _getNameRouteMatch(
    String name, {
    Map<String, String> params = const {},
    Map<String, String> queryParams = const {},
    Object? extra,
  }) {
    final partialMatch = _namedMatches[name];
    return partialMatch == null
        ? null
        : GoRouteMatch._matchNamed(
            name: name,
            route: partialMatch.route,
            fullpath: partialMatch.fullpath,
            params: params,
            queryParams: queryParams,
            extra: extra,
          );
  }

  // e.g.
  // parentFullLoc: '',          path =>                  '/'
  // parentFullLoc: '/',         path => 'family/:fid' => '/family/:fid'
  // parentFullLoc: '/',         path => 'family/f2' =>   '/family/f2'
  // parentFullLoc: '/family/f2', path => 'parent/p1' =>   '/family/f2/person/p1'
  static String _fullLocFor(String parentFullLoc, String path) {
    // at the root, just return the path
    if (parentFullLoc.isEmpty) {
      assert(path.startsWith('/'));
      assert(path == '/' || !path.endsWith('/'));
      return path;
    }

    // not at the root, so append the parent path
    assert(path.isNotEmpty);
    assert(!path.startsWith('/'));
    assert(!path.endsWith('/'));
    return '${parentFullLoc == '/' ? '' : parentFullLoc}/$path';
  }

  Widget _builder(BuildContext context, Iterable<GoRouteMatch> matches) {
    List<Page<dynamic>> pages;

    try {
      // build the stack of pages
      pages = getPages(context, matches.toList()).toList();
    } on Exception catch (ex) {
      _log(ex.toString());

      // if there's an error, show an error page
      final uri = Uri.parse(location);
      pages = [
        errorPageBuilder(
          context,
          GoRouterState(
            this,
            location: location,
            subloc: uri.path,
            name: null,
            queryParams: uri.queryParameters,
            error: ex,
          ),
        ),
      ];
    }

    // wrap the returned Navigator to enable GoRouter.of(context).go()
    return builderWithNav(
      context,
      Navigator(
        restorationScopeId: restorationScopeId,
        key: _key, // needed to enable Android system Back button
        pages: pages,
        observers: observers,
        onPopPage: (route, dynamic result) {
          if (!route.didPop(result)) return false;

          _log2('GoRouterDelegate.onPopPage: matches.last= ${_matches.last}');
          _matches.remove(_matches.last);
          if (_matches.isEmpty)
            throw Exception('have popped the last page off of the stack; '
                'there are no pages left to show');

          // this hack allows the browser's address bar to be updated after a
          // push and pressing the Back button, but it shouldn't be necessary...
          _safeNotifyListeners();

          return true;
        },
      ),
    );
  }

  /// Get the stack of sub-routes that matches the location and turn it into a
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
  /// pages: [ HomePage(), FamilyPage(f2) ]
  ///
  /// loc: /family/f2/person/p1
  /// pages: [ HomePage(), FamilyPage(f2), PersonPage(f2, p1) ]
  @visibleForTesting
  Iterable<Page<dynamic>> getPages(
    BuildContext context,
    List<GoRouteMatch> matches,
  ) sync* {
    assert(matches.isNotEmpty);

    var params = <String, String>{};
    for (final match in matches) {
      // merge new params to keep params from previously matched paths, e.g.
      // /family/:fid/person/:pid provides fid and pid to person/:pid
      params = {...params, ...match.params};

      // get a page from the builder and associate it with a sub-location
      yield match.route.pageBuilder(
        context,
        GoRouterState(
          this,
          location: location,
          subloc: match.subloc,
          name: match.route.name,
          path: match.route.path,
          fullpath: match.fullpath,
          params: params,
          queryParams: match.queryParams,
          extra: match.extra,
          pageKey: match.pageKey, // push() remaps the page key for uniqueness
        ),
      );
    }
  }

  void _outputKnownRoutes() {
    if (!debugLogDiagnostics) return;
    _log('known full paths for routes:');
    _outputFullPathsFor(routes, '', 0);

    if (_namedMatches.isNotEmpty) {
      _log('known full paths for route names:');
      for (final e in _namedMatches.entries) {
        _log('  ${e.key} => ${e.value.fullpath}');
      }
    }
  }

  void _outputFullPathsFor(
    List<GoRoute> routes,
    String parentFullpath,
    int depth,
  ) {
    assert(debugLogDiagnostics);

    for (final route in routes) {
      final fullpath = _fullLocFor(parentFullpath, route.path);
      _log('  => ${''.padLeft(depth * 2)}$fullpath');
      _outputFullPathsFor(route.routes, fullpath, depth + 1);
    }
  }

  // e.g. %20 => +
  static String _canonicalUri(String loc) {
    final uri = Uri.parse(loc);
    final canon = Uri.decodeFull(
      Uri(path: uri.path, queryParameters: uri.queryParameters).toString(),
    );
    return canon.endsWith('?') ? canon.substring(0, canon.length - 1) : canon;
  }

  static String _addQueryParams(String loc, Map<String, String> queryParams) {
    final uri = Uri.parse(loc);
    assert(uri.queryParameters.isEmpty);
    return _canonicalUri(
        Uri(path: uri.path, queryParameters: queryParams).toString());
  }

  void _safeNotifyListeners() {
    _log2('GoRouterDelegate.safeNotifyListeners: WidgetsBinding.instance= '
        '${WidgetsBinding.instance == null ? 'null' : 'non-null'}');

    // this is a hack to fix the following error:
    // The following assertion was thrown while dispatching notifications for
    // GoRouterDelegate: setState() or markNeedsBuild() called during build.
    WidgetsBinding.instance == null
        ? notifyListeners()
        : scheduleMicrotask(notifyListeners);
  }
}

/// GoRouter implementation of the RouteInformationParser base class
class GoRouteInformationParser extends RouteInformationParser<Uri> {
  /// for use by the Router architecture as part of the RouteInformationParser
  @override
  Future<Uri> parseRouteInformation(RouteInformation routeInformation) async {
    _log2('GoRouteInformationParser.parseRouteInformation: '
        'routeInformation.location= ${routeInformation.location}');
    return Uri.parse(routeInformation.location!);
  }

  /// for use by the Router architecture as part of the RouteInformationParser
  @override
  RouteInformation restoreRouteInformation(Uri configuration) {
    _log2('GoRouteInformationParser.parseRouteInformation: '
        'configuration= $configuration');
    return RouteInformation(location: configuration.toString());
  }
}

/// GoRouter implementation of InheritedWidget.
///
/// Used for to find the current GoRouter in the widget tree. This is useful
/// when routing from anywhere in your app.
class InheritedGoRouter extends InheritedWidget {
  /// Default constructor for the inherited go router.
  const InheritedGoRouter({
    required Widget child,
    required this.goRouter,
    Key? key,
  }) : super(child: child, key: key);

  /// The [GoRouter] that is made available to the widget tree.
  final GoRouter goRouter;

  /// Used by the Router architecture as part of the InheritedWidget.
  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;
}

/// Each GoRouteMatch instance represents an instance of a GoRoute for a
/// specific portion of a location.
class GoRouteMatch {
  /// Constructor for GoRouteMatch, each instance represents an instance of a
  /// GoRoute for a specific portion of a location.
  GoRouteMatch({
    required this.route,
    required this.subloc,
    required this.fullpath,
    required this.params,
    required this.queryParams,
    required this.extra,
    this.pageKey,
  })  : assert(subloc.startsWith('/')),
        assert(Uri.parse(subloc).queryParameters.isEmpty),
        assert(fullpath.startsWith('/')),
        assert(Uri.parse(fullpath).queryParameters.isEmpty);

  /// The matched route.
  final GoRoute route;

  /// Matched sub-location.
  final String subloc; // e.g. /family/f2

  /// Matched full path.
  final String fullpath; // e.g. /family/:fid

  /// Parameters for the matched route.
  final Map<String, String> params;

  /// Query parameters for the matched route.
  final Map<String, String> queryParams;

  /// An extra object to pass along with the navigation.
  final Object? extra;

  /// Optional value key of type string, to hold a unique reference to a page.
  final ValueKey<String>? pageKey;

  static GoRouteMatch? _match({
    required GoRoute route,
    required String restLoc, // e.g. person/p1
    required String parentSubloc, // e.g. /family/f2
    required String path, // e.g. person/:pid
    required String fullpath, // e.g. /family/:fid/person/:pid
    required Map<String, String> queryParams,
    required Object? extra,
  }) {
    assert(!path.contains('//'));

    final match = route.matchPatternAsPrefix(restLoc);
    if (match == null) return null;

    final params = route.extractPathParams(match);
    final pathLoc = _locationFor(path, params);
    final subloc = GoRouterDelegate._fullLocFor(parentSubloc, pathLoc);
    return GoRouteMatch(
      route: route,
      subloc: subloc,
      fullpath: fullpath,
      params: params,
      queryParams: queryParams,
      extra: extra,
    );
  }

  // ignore: prefer_constructors_over_static_methods
  static GoRouteMatch _matchNamed({
    required GoRoute route,
    required String name, // e.g. person
    required String fullpath, // e.g. /family/:fid/person/:pid
    required Map<String, String> params, // e.g. {'fid': 'f2', 'pid': 'p1'}
    required Map<String, String> queryParams, // e.g. {'from': '/family/f2'}
    required Object? extra,
  }) {
    assert(route.name != null);
    assert(route.name!.toLowerCase() == name.toLowerCase());

    // check that we have all the params we need
    final paramNames = <String>[];
    p2re.parse(fullpath, parameters: paramNames);
    for (final paramName in paramNames) {
      if (!params.containsKey(paramName)) {
        throw Exception('missing param "$paramName" for $fullpath');
      }
    }

    // check that we have don't have extra params
    for (final key in params.keys) {
      if (!paramNames.contains(key)) {
        throw Exception('unknown param "$key" for $fullpath');
      }
    }

    final subloc = _locationFor(fullpath, params);
    return GoRouteMatch(
      route: route,
      subloc: subloc,
      fullpath: fullpath,
      params: params,
      queryParams: queryParams,
      extra: extra,
    );
  }

  /// for use by the Router architecture as part of the GoRouteMatch
  @override
  String toString() => 'GoRouteMatch($fullpath, $params)';

  /// expand a path w/ param slots using params, e.g. family/:fid => family/f1
  static String _locationFor(String path, Map<String, String> params) =>
      p2re.pathToFunction(path)(params);
}
