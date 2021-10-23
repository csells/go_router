import 'package:flutter/foundation.dart';

import 'go_router_delegate.dart';

class GoRedirectState {
  GoRedirectState(
    this._delegate, {
    required this.location,
    required this.subloc,
    required this.queryParams,
  });
  final GoRouterDelegate _delegate;

  /// The full location of the route, e.g. /family/f2/person/p1
  final String location;

  /// The location of this sub-route, e.g. /family/f2
  final String subloc;

  /// The query parameters for the location, e.g. {'from': '/family/f2'}
  final Map<String, String> queryParams;

  /// Get a location from route name and parameters.
  /// This is useful for redirecting to a named location.
  String namedLocation(
    String name, {
    Map<String, String> params = const {},
    Map<String, String> queryParams = const {},
  }) =>
      _delegate.namedLocation(name, params: params, queryParams: queryParams);
}

/// The route state during routing.
class GoRouterState extends GoRedirectState {
  /// Default constructor for creating route state during routing.
  GoRouterState(
    GoRouterDelegate delegate, {
    required String location,
    required String subloc,
    required this.name,
    this.path,
    this.fullpath,
    this.params = const {},
    Map<String, String> queryParams = const {},
    this.extra,
    this.error,
    ValueKey<String>? pageKey,
  })  : pageKey = pageKey ??
            ValueKey(error != null
                ? 'error'
                : fullpath != null && fullpath.isNotEmpty
                    ? fullpath
                    : subloc),
        assert((path ?? '').isEmpty == (fullpath ?? '').isEmpty),
        super(
          delegate,
          location: location,
          subloc: subloc,
          queryParams: queryParams,
        );

  /// The optional name of the route.
  final String? name;

  /// The path to this sub-route, e.g. family/:fid
  final String? path;

  /// The full path to this sub-route, e.g. /family/:fid
  final String? fullpath;

  /// The parameters for this sub-route, e.g. {'fid': 'f2'}
  final Map<String, String> params;

  /// An extra object to pass along with the navigation.
  final Object? extra;

  /// The error associated with this sub-route.
  final Exception? error;

  /// A unique string key for this sub-route, e.g. ValueKey('/family/:fid')
  final ValueKey<String> pageKey;
}
