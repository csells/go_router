import 'package:flutter/widgets.dart';

import 'go_route_match.dart';
import 'go_router_state.dart';

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

/// The signature of the page builder callback for a matched GoRoute.
typedef GoRouterPageBuilder = Page<dynamic> Function(
  BuildContext context,
  GoRouterState state,
);

/// The signature of the redirect callback.
typedef GoRouterRedirect = String? Function(GoRouterState state);

/// TODO
typedef GoTopRedirect = String? Function(GoRedirectState state);
