import 'package:flutter/foundation.dart';
import 'package:path_to_regexp/path_to_regexp.dart' as p2re;

import 'go_route.dart';
import 'go_router_delegate.dart';

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

  // ignore: public_member_api_docs
  static GoRouteMatch? match({
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
    final subloc = GoRouterDelegate.fullLocFor(parentSubloc, pathLoc);
    return GoRouteMatch(
      route: route,
      subloc: subloc,
      fullpath: fullpath,
      params: params,
      queryParams: queryParams,
      extra: extra,
    );
  }

  // ignore: prefer_constructors_over_static_methods, public_member_api_docs
  static GoRouteMatch matchNamed({
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
