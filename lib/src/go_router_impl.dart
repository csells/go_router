import 'package:flutter/widgets.dart';
import '../go_router.dart';

typedef GoRouterBuilder = Widget Function(
  BuildContext context,
  Iterable<GoRouteMatch> matches,
);

/// GoRouter implementation of the RouterDelegate base class
class GoRouterDelegate extends RouterDelegate<Uri>
    with
        PopNavigatorRouterDelegateMixin<Uri>,
        // ignore: prefer_mixin
        ChangeNotifier {
  final GoRouterBuilder builder;
  final List<GoRoute> routes;
  final GoRouterRedirect topRedirect;
  final Listenable? refreshListenable;

  final _key = GlobalKey<NavigatorState>();
  final List<GoRouteMatch> _matches = [];

  GoRouterDelegate({
    required this.builder,
    required this.routes,
    required this.topRedirect,
    this.refreshListenable,
    Uri? initUri,
    bool debugOutputFullPaths = false,
  }) {
    // check that the route paths are valid
    for (final route in routes) {
      if (!route.path.startsWith('/')) {
        throw Exception('top-level path must start with "/": ${route.path}');
      }
    }

    // build the list of route matches
    _go((initUri ?? Uri()).toString());

    // when the listener changes, refresh the route
    refreshListenable?.addListener(refresh);

    // output known routes
    if (debugOutputFullPaths) _outputFullPaths();
  }

  void go(String location) {
    _go(location);
    notifyListeners();
  }

  void refresh() {
    _go(_matches.last.subloc);
    notifyListeners();
  }

  String get location => _matches.last.subloc;

  // TODO: make this private
  void pop() => _matches.remove(_matches.last);

  @override
  void dispose() {
    refreshListenable?.removeListener(refresh);
    super.dispose();
  }

  @override
  GlobalKey<NavigatorState> get navigatorKey => _key;

  @override
  Uri get currentConfiguration => Uri.parse(location);

  @override
  Widget build(BuildContext context) => builder(context, _matches);

  @override
  Future<void> setInitialRoutePath(Uri configuration) async {
    // if the initial location is /, then use the dev initial location;
    // otherwise, we're cruising to a deep link, so ignore dev initial location
    final config = configuration.toString();
    _go(config == '/' ? location : config);
  }

  @override
  Future<void> setNewRoutePath(Uri configuration) async =>
      _go(configuration.toString());

  void _go(String location) {
    assert(Uri.tryParse(location) != null);

    // watch redirects for loops
    var loc = location;
    final redirects = List<String>.filled(1, loc, growable: true);
    bool redirected(String? redir) {
      if (redir == null) return false;

      if (redirects.contains(redir)) {
        final msg = 'Redirect loop detected: ${redirects.join(' => ')}';
        throw Exception(msg);
      }

      loc = redir;
      return true;
    }

    // keep looping till we're done redirecting
    for (;;) {
      // check for top-level redirect
      if (redirected(topRedirect(loc))) continue;

      // get stack of route matches
      final matches = getLocRouteMatches(loc);

      // check top route for redirect
      if (redirected(matches.last.route.redirect(loc))) continue;

      // no more redirects!
      _matches.clear();
      _matches.addAll(matches);
      break;
    }
  }

  /// Call _getLocRouteMatchStacks and check for errors
  @visibleForTesting
  List<GoRouteMatch> getLocRouteMatches(String location) {
    final loc = Uri.parse(location).path;
    final matchStacks = _getLocRouteMatchStacks(
      loc: loc,
      partLoc: loc,
      routes: routes,
      parentFullpath: '',
    ).toList();

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
    assert(matchStacks.first.last.subloc.toLowerCase() == loc.toLowerCase());
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
    required String partLoc,
    required List<GoRoute> routes,
    required String parentFullpath,
  }) sync* {
    // assume somebody else has removed the query params
    assert(Uri.parse(partLoc).path == partLoc);

    // find the set of matches at this level of the tree
    for (final route in routes) {
      final fullpath = _fullpathFor(parentFullpath, route.path);
      final match = GoRouteMatch.match(
        route: route,
        partLoc: partLoc,
        fullpath: fullpath,
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
      final rest = partLoc
          .substring(match.subloc.length + (match.subloc == '/' ? 0 : 1));
      assert(loc.startsWith(match.subloc));
      assert(rest.isNotEmpty);

      // if there's no sub-route matches, then we don't have a match for this
      // location
      final subRouteMatchStacks = _getLocRouteMatchStacks(
        loc: loc,
        partLoc: rest,
        routes: route.routes,
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

  void _outputFullPaths() {
    // ignore: avoid_print
    print('');
    // ignore: avoid_print
    print('GoRouter: full paths');
    _outputFullPathsFor(routes, '', 0);
    // ignore: avoid_print
    print('');
  }

  void _outputFullPathsFor(
    List<GoRoute> routes,
    String parentFullpath,
    int depth,
  ) {
    for (final route in routes) {
      final fullpath = _fullpathFor(parentFullpath, route.path);
      // ignore: avoid_print
      print('${''.padLeft(depth * 2)}$fullpath');
      _outputFullPathsFor(route.routes, fullpath, depth + 1);
    }
  }
}

/// GoRouter implementation of the RouteInformationParser base class
class GoRouteInformationParser extends RouteInformationParser<Uri> {
  @override
  Future<Uri> parseRouteInformation(RouteInformation routeInformation) async =>
      Uri.parse(routeInformation.location!);

  @override
  RouteInformation restoreRouteInformation(Uri configuration) =>
      RouteInformation(location: configuration.toString());
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
  final String subloc;
  final String fullpath;
  final Map<String, String> params;
  GoRouteMatch({
    required this.route,
    required this.subloc,
    required this.fullpath,
    required this.params,
  })  : assert(subloc.startsWith('/')),
        assert(fullpath.startsWith('/'));

  static GoRouteMatch? match({
    required GoRoute route,
    required String partLoc,
    required String fullpath,
  }) {
    assert(!fullpath.contains('//'));

    final match = route.matchPatternAsPrefix(partLoc);
    if (match == null) return null;

    final params = route.extractPatternParams(match);
    final subloc = GoRouter.locationFor(fullpath, params);
    return GoRouteMatch(
      route: route,
      subloc: subloc,
      fullpath: fullpath,
      params: params,
    );
  }
}
