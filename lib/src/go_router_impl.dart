import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_to_regexp/path_to_regexp.dart' as p2re;

import '../go_router.dart';

const _debugLog2Diagnostics = true;

void _log2(String s) {
  if (_debugLog2Diagnostics) debugPrint(s);
}

typedef GoRouterBuilderWithMatches = Widget Function(
  BuildContext context,
  Iterable<GoRouteMatch> matches,
);

typedef GoRouterBuilderWithNav = Widget Function(
  BuildContext context,
  Navigator navigator,
);

/// GoRouter implementation of the RouterDelegate base class
class GoRouterDelegate extends RouterDelegate<Uri>
    with
        PopNavigatorRouterDelegateMixin<Uri>,
        // ignore: prefer_mixin
        ChangeNotifier {
  final GoRouterBuilderWithNav builderWithNav;
  final List<GoRoute> routes;
  final GoRouterPageBuilder errorBuilder;
  final GoRouterRedirect topRedirect;
  final Listenable? refreshListenable;
  final bool debugLogDiagnostics;

  final _key = GlobalKey<NavigatorState>();
  final List<GoRouteMatch> _matches = [];

  GoRouterDelegate({
    required this.builderWithNav,
    required this.routes,
    required this.errorBuilder,
    required GoRouterRedirect? topRedirect,
    required this.refreshListenable,
    required Uri? initUri,
    required this.debugLogDiagnostics,
  }) : topRedirect = topRedirect ?? _redirect {
    // check that the route paths are valid
    for (final route in routes) {
      if (!route.path.startsWith('/')) {
        throw Exception('top-level path must start with "/": ${route.path}');
      }
    }

    // output known full paths for routes
    _outputFullPaths();

    // build the list of route matches
    _go((initUri ?? Uri()).toString());

    // when the listener changes, refresh the route
    refreshListenable?.addListener(refresh);
  }

  void go(String location) {
    _go(location);
    safeNotifyListeners();
  }

  void refresh() {
    _go(_matches.last.subloc);
    safeNotifyListeners();
  }

  String get location =>
      _addQueryParams(_matches.last.subloc, _matches.last.queryParams);

  @visibleForTesting
  List<GoRouteMatch> get matches => _matches;

  @override
  void dispose() {
    refreshListenable?.removeListener(refresh);
    super.dispose();
  }

  @override
  GlobalKey<NavigatorState> get navigatorKey => _key;

  @override
  Uri get currentConfiguration {
    _log2('GoRouterDelegate.currentConfiguration: $location');
    return Uri.parse(location);
  }

  @override
  Widget build(BuildContext context) {
    _log2('GoRouterDelegate.build: matches=');
    for (final match in matches) _log2('  GoRouterDelegate.build: $match');
    return _builder(context, _matches);
  }

  @override
  Future<void> setInitialRoutePath(Uri configuration) async {
    _log2(
        'GoRouterDelegate.setInitialRoutePath: configuration= $configuration');

    // if the initial location is /, then use the dev initial location;
    // otherwise, we're cruising to a deep link, so ignore dev initial location
    final config = configuration.toString();
    _go(config == '/' ? location : config);
  }

  @override
  Future<void> setNewRoutePath(Uri configuration) async {
    _log2('GoRouterDelegate.setNewRoutePath: configuration= $configuration');
    _go(configuration.toString());
  }

  void _log(Object o) {
    if (debugLogDiagnostics) debugPrint('GoRouter: $o');
  }

  static String? _redirect(String location) => null;

  void _go(String location) {
    _log('going to $location');

    // start redirecting from the initial location
    List<GoRouteMatch> matches;

    try {
      // watch redirects for loops
      final redirects = [_canonicalUri(location)];
      bool redirected(String? redir) {
        if (redir == null) return false;

        if (redirects.contains(redir)) {
          redirects.add(redir);
          final msg = 'Redirect loop detected: ${redirects.join(' => ')}';
          throw Exception(msg);
        }

        redirects.add(redir);
        _log('redirecting to $redir');
        return true;
      }

      // keep looping till we're done redirecting
      for (;;) {
        final loc = redirects.last;

        // check for top-level redirect
        if (redirected(topRedirect(loc))) continue;

        // get stack of route matches
        matches = getLocRouteMatches(loc);

        // check top route for redirect
        if (redirected(matches.last.route.redirect(loc))) continue;

        // let Router know to update the address bar
        if (redirects.length > 1) // the initial route is not a redirect
          safeNotifyListeners();

        // no more redirects!
        break;
      }
    } on Exception catch (ex) {
      // create a match that routes to the error page
      final uri = Uri.parse(location);
      matches = [
        GoRouteMatch(
          subloc: uri.path,
          fullpath: uri.path,
          params: {},
          queryParams: uri.queryParameters,
          route: GoRoute(
            path: location,
            builder: (context, state) => errorBuilder(
              context,
              GoRouterState(
                location: state.location,
                subloc: state.subloc,
                error: ex,
                fullpath: '',
              ),
            ),
          ),
        ),
      ];
    }

    // update the matches
    assert(matches.isNotEmpty);
    _matches.clear();
    _matches.addAll(matches);
  }

  /// Call _getLocRouteMatchStacks and check for errors
  @visibleForTesting
  List<GoRouteMatch> getLocRouteMatches(String location) {
    final uri = Uri.parse(location);
    final matchStacks = _getLocRouteMatchStacks(
      loc: uri.path,
      restLoc: uri.path,
      routes: routes,
      parentFullpath: '',
      parentSubloc: '',
      queryParams: uri.queryParameters,
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
      final loc1 = _addQueryParams(
        match.subloc.toLowerCase(),
        match.queryParams,
      );
      final loc2 = _canonicalUri(location.toLowerCase());
      assert(loc1 == loc2);
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
  }) sync* {
    // find the set of matches at this level of the tree
    for (final route in routes) {
      final fullpath = _fullLocFor(parentFullpath, route.path);
      final match = GoRouteMatch.match(
        route: route,
        restLoc: restLoc,
        parentSubloc: parentSubloc,
        path: route.path,
        fullpath: fullpath,
        queryParams: queryParams,
      );
      if (match == null) continue;

      // if we have a complete match, then return the matched route
      if (match.subloc == loc) {
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
      ).toList();
      if (subRouteMatchStacks.isEmpty) continue;

      // add the match to each of the sub-route match stacks and return them
      for (final stack in subRouteMatchStacks) yield [match, ...stack];
    }
  }

  // e.g.
  // parentFullLoc: '',          path =>                  '/'
  // parentFullLoc: '/',         path => 'family/:fid' => '/family/:fid'
  // parentFullLoc: '/',         path => 'family/f2' =>   '/family/f2'
  // parentFullLoc: '/famiy/f2', path => 'parent/p1' =>   '/family/f2/person/p1'
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
      // if there's an error, show an error page
      pages = [
        errorBuilder(
          context,
          GoRouterState(
            location: location,
            subloc: location,
            error: ex,
          ),
        ),
      ];
    }

    // wrap the returned Navigator to enable GoRouter.of(context).go()
    return builderWithNav(
      context,
      Navigator(
        pages: pages,
        onPopPage: (route, dynamic result) {
          if (!route.didPop(result)) return false;

          _log2('GoRouterDelegate.onPopPage: matches.last= ${_matches.last}');
          _matches.remove(_matches.last);

          return true;
        },
      ),
    );
  }

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
    var params = matches.first.queryParams; // start w/ the query parameters
    if (kDebugMode) {
      for (final match in matches) {
        assert(match.queryParams == matches.first.queryParams);
      }
    }

    for (final match in matches) {
      // merge new params, overriding old ones, i.e. path params override
      // query parameters, sub-location params override top level params, etc.
      // this also keeps params from previously matched paths, e.g.
      // /family/:fid/person/:pid provides fid and pid to person/:pid
      params = {...params, ...match.params};

      // get a page from the builder and associate it with a sub-location
      yield match.route.builder(
        context,
        GoRouterState(
          location: location,
          subloc: match.subloc,
          path: match.route.path,
          fullpath: match.fullpath,
          params: params,
        ),
      );
    }
  }

  void _outputFullPaths() {
    if (!debugLogDiagnostics) return;
    _log('known full paths for routes');
    _outputFullPathsFor(routes, '', 0);
  }

  void _outputFullPathsFor(
    List<GoRoute> routes,
    String parentFullpath,
    int depth,
  ) {
    assert(debugLogDiagnostics);

    for (final route in routes) {
      final fullpath = _fullLocFor(parentFullpath, route.path);
      _log('=> ${''.padLeft(depth * 2)}$fullpath');
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

  // HACK: this is a hack to fix the following error:
  // The following assertion was thrown while dispatching notifications for
  // GoRouterDelegate: setState() or markNeedsBuild() called during build.
  void safeNotifyListeners() {
    _log2(
        'GoRouterDelegate.safeNotifyListeners: WidgetsBinding.instance= ${WidgetsBinding.instance == null ? 'null' : 'non-null'}');

    final instance = WidgetsBinding.instance;
    if (instance != null)
      instance.addPostFrameCallback((_) => notifyListeners());
    else
      notifyListeners();
  }
}

/// GoRouter implementation of the RouteInformationParser base class
class GoRouteInformationParser extends RouteInformationParser<Uri> {
  @override
  Future<Uri> parseRouteInformation(RouteInformation routeInformation) async {
    _log2(
        'GoRouteInformationParser.parseRouteInformation: routeInformation= $routeInformation');
    return Uri.parse(routeInformation.location!);
  }

  @override
  RouteInformation restoreRouteInformation(Uri configuration) {
    _log2(
        'GoRouteInformationParser.parseRouteInformation: configuration= $configuration');
    return RouteInformation(location: configuration.toString());
  }
}

/// GoRouter implementation of InheritedWidget for purposes of finding the
/// current GoRouter in the widget tree. This is useful when routing from
/// anywhere in your app.
class InheritedGoRouter extends InheritedWidget {
  final GoRouter goRouter;
  const InheritedGoRouter({
    required Widget child,
    required this.goRouter,
    Key? key,
  }) : super(child: child, key: key);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;
}

class GoRouteMatch {
  final GoRoute route;
  final String subloc; // e.g. /family/f2
  final String fullpath; // e.g. /family/:fid
  final Map<String, String> params;
  final Map<String, String> queryParams;
  GoRouteMatch({
    required this.route,
    required this.subloc,
    required this.fullpath,
    required this.params,
    required this.queryParams,
  })  : assert(subloc.startsWith('/')),
        assert(Uri.parse(subloc).queryParameters.isEmpty),
        assert(fullpath.startsWith('/')),
        assert(Uri.parse(fullpath).queryParameters.isEmpty);

  static GoRouteMatch? match({
    required GoRoute route,
    required String restLoc, // e.g. person/p1
    required String parentSubloc, // e.g. /family/f2
    required String path, // e.g. person/:pid
    required String fullpath, // e.g. /family/:fid/person/:pid
    required Map<String, String> queryParams,
  }) {
    assert(!path.contains('//'));

    final match = route.matchPatternAsPrefix(restLoc);
    if (match == null) return null;

    final params = route.extractPatternParams(match);
    final pathLoc = _locationFor(path, params);
    final subloc = GoRouterDelegate._fullLocFor(parentSubloc, pathLoc);
    return GoRouteMatch(
      route: route,
      subloc: subloc,
      fullpath: fullpath,
      params: params,
      queryParams: queryParams,
    );
  }

  @override
  String toString() => 'GoRouteMatch($fullpath, $params)';

  /// expand a path w/ param slots using params, e.g. family/:fid => family/f1
  static String _locationFor(String path, Map<String, String> params) =>
      p2re.pathToFunction(path)(params);
}
