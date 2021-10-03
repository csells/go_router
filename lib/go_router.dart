/// A declarative router for Flutter based on Navigation 2 supporting
/// deep linking, data-driven routes and more
library go_router;

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:path_to_regexp/path_to_regexp.dart' as p2re;

import 'src/go_router_impl.dart';
import 'src/path_strategy_nonweb.dart'
    if (dart.library.html) 'src/path_strategy_web.dart';

/// The path strategy for use in GoRouter.setUrlPathStrategy.
enum UrlPathStrategy {
  /// Use hash url strategy.
  hash,

  /// Use path url strategy.
  path,
}

/// The signature of the page builder callback for a matched GoRoute.
typedef GoRouterPageBuilder = Page<dynamic> Function(
  BuildContext context,
  GoRouterState state,
);

/// The signature of the redirect callback.
typedef GoRouterRedirect = String? Function(GoRouterState state);

/// The route state during routing.
class GoRouterState {
  /// Default constructor for creating route state during routing.
  GoRouterState({
    required this.location,
    required this.subloc,
    this.path,
    this.fullpath,
    this.params = const <String, String>{},
    this.error,
    ValueKey<String>? pageKey,
  })  : pageKey = pageKey ??
            ValueKey(error != null
                ? 'error'
                : fullpath != null && fullpath.isNotEmpty
                    ? fullpath
                    : subloc),
        assert((path ?? '').isEmpty == (fullpath ?? '').isEmpty);

  /// The full location of the route, e.g. /family/f1/person/p2
  final String location;

  /// The location of this sub-route, e.g. /family/f1
  final String subloc;

  /// The path to this sub-route, e.g. family/:fid
  final String? path;

  /// The full path to this sub-route, e.g. /family/:fid
  final String? fullpath;

  /// The parameters for this sub-route, e.g. {'fid': 'f1'}
  final Map<String, String> params;

  /// The error associated with this sub-route.
  final Exception? error;

  /// A unique string key for this sub-route, e.g. ValueKey('/family/:fid')
  final ValueKey<String> pageKey;
}

/// A declarative mapping between a route path and a page builder.
class GoRoute {
  /// Default constructor used to create mapping between a
  /// route path and a page builder.
  GoRoute({
    required this.path,
    this.name,
    this.pageBuilder = _builder,
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

  final _pathParams = <String>[];
  late final RegExp _pathRE;

  /// Optional name of the route.
  ///
  /// If used, a unique string name must be provided and it can not be empty.
  final String? name;

  /// The path of this go route.
  ///
  /// For example in:
  /// ```
  /// GoRoute(
  ///   path: '/',
  ///   pageBuilder: (context, state) => MaterialPage<void>(
  ///   key: state.pageKey,
  ///   child: HomePage(families: Families.data),
  /// ),
  /// ```
  final String path;

  /// A page builder for this route.
  ///
  /// Typically a MaterialPage, as in:
  /// ```
  /// GoRoute(
  ///   path: '/',
  ///   pageBuilder: (context, state) => MaterialPage<void>(
  ///   key: state.pageKey,
  ///   child: HomePage(families: Families.data),
  /// ),
  /// ```
  ///
  /// You can also use CupertinoPage, and for a custom page builder to use
  /// custom page transitions, you can use [CustomTransitionPage].
  final GoRouterPageBuilder pageBuilder;

  /// A list of sub go routes for this route.
  ///
  /// To create sub-routes for a route, provide them as a [GoRoute] list
  /// with the sub routes.
  ///
  /// For example these routes:
  /// ```
  /// /             => HomePage()
  ///   family/f1   => FamilyPage('f1')
  ///     person/p2 => PersonPage('f1', 'p2') ← showing this page, Back pops ↑
  /// ```
  ///
  /// Can be represented as:
  ///
  /// ```
  /// final _router = GoRouter(
  ///   routes: [
  ///     GoRoute(
  ///       path: '/',
  ///       pageBuilder: (context, state) => MaterialPage<void>(
  ///         key: state.pageKey,
  ///         child: HomePage(families: Families.data),
  ///       ),
  ///       routes: [
  ///         GoRoute(
  ///           path: 'family/:fid',
  ///           pageBuilder: (context, state) {
  ///             final family = Families.family(state.params['fid']!);
  ///             return MaterialPage<void>(
  ///               key: state.pageKey,
  ///               child: FamilyPage(family: family),
  ///             );
  ///           },
  ///           routes: [
  ///             GoRoute(
  ///               path: 'person/:pid',
  ///               pageBuilder: (context, state) {
  ///                 final family = Families.family(state.params['fid']!);
  ///                 final person = family.person(state.params['pid']!);
  ///                 return MaterialPage<void>(
  ///                   key: state.pageKey,
  ///                   child: PersonPage(family: family, person: person),
  ///                 );
  ///               },
  ///             ),
  ///           ],
  ///         ),
  ///       ],
  ///     ),
  ///   ],
  ///   errorPageBuilder: ...
  /// );
  ///
  final List<GoRoute> routes;

  /// An optional redirect function for this route.
  ///
  /// In the case that you like to make a redirection decision for a specific
  /// route (or sub-route), you can do so by passing a redirect function to
  /// the GoRoute constructor.
  ///
  /// For example:
  /// ```
  /// final _router = GoRouter(
  ///   routes: [
  ///     GoRoute(
  ///       path: '/',
  ///       redirect: (_) => '/family/${Families.data[0].id}',
  ///     ),
  ///     GoRoute(
  ///       path: '/family/:fid',
  ///       pageBuilder: ...,
  ///   ],
  ///   errorPageBuilder: ...,
  /// );
  /// ```
  final GoRouterRedirect redirect;

  /// Match this route against a location.
  Match? matchPatternAsPrefix(String loc) => _pathRE.matchAsPrefix(loc);

  /// Extract the path parameters from a match.
  Map<String, String> extractPathParams(Match match) =>
      p2re.extract(_pathParams, match);

  static String? _redirect(GoRouterState state) => null;

  static Page<dynamic> _builder(BuildContext context, GoRouterState state) =>
      throw Exception('GoRoute builder parameter not set');
}

/// The top-level go router class.
///
/// Create one of these to initialize your app's routing policy.
// ignore: prefer_mixin
class GoRouter extends ChangeNotifier with NavigatorObserver {
  /// Default constructor to configure a GoRouter with a routes builder
  /// and an error page builder.
  GoRouter({
    required List<GoRoute> routes,
    required GoRouterPageBuilder errorPageBuilder,
    GoRouterRedirect? redirect,
    Listenable? refreshListenable,
    String initialLocation = '/',
    UrlPathStrategy? urlPathStrategy,
    List<NavigatorObserver>? observers,
    bool debugLogDiagnostics = false,
  }) {
    if (urlPathStrategy != null) setUrlPathStrategy(urlPathStrategy);

    routerDelegate = GoRouterDelegate(
      routes: routes,
      errorPageBuilder: errorPageBuilder,
      topRedirect: redirect ?? (_) => null,
      refreshListenable: refreshListenable,
      initUri: Uri.parse(initialLocation),
      observers: [...observers ?? [], this],
      debugLogDiagnostics: debugLogDiagnostics,
      // wrap the returned Navigator to enable GoRouter.of(context).go() et al
      builderWithNav: (context, nav) =>
          InheritedGoRouter(goRouter: this, child: nav),
    );
  }

  /// The route information parser used by the go router.
  final routeInformationParser = GoRouteInformationParser();

  /// The router delegate used by the go router.
  late final GoRouterDelegate routerDelegate;

  /// Get the current location.
  String get location => routerDelegate.currentConfiguration.toString();

  /// Navigate to a URI location w/ optional query parameters, e.g.
  /// /family/f2/person/p1?color=blue
  void go(String location) => routerDelegate.go(location);

  /// Navigate to a named route w/ optional parameters, e.g.
  /// name='person', params={'fid': 'f2', 'pid': 'p1'}
  void goNamed(String name, [Map<String, String> params = const {}]) =>
      routerDelegate.goNamed(name, params);

  /// Push a URI location onto the page stack w/ optional query parameters, e.g.
  /// /family/f2/person/p1?color=blue
  void push(String location) => routerDelegate.push(location);

  /// Push a named route onto the page stack w/ optional parameters, e.g.
  /// name='person', params={'fid': 'f2', 'pid': 'p1'}
  void pushNamed(String name, [Map<String, String> params = const {}]) =>
      routerDelegate.pushNamed(name, params);

  /// Refresh the route.
  void refresh() => routerDelegate.refresh();

  /// Set the app's URL path strategy (defaults to hash). call before runApp().
  static void setUrlPathStrategy(UrlPathStrategy strategy) =>
      setUrlPathStrategyImpl(strategy);

  /// Find the current GoRouter in the widget tree.
  static GoRouter of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedGoRouter>()!.goRouter;

  /// The [Navigator] pushed `route`.
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      notifyListeners();

  /// The [Navigator] popped `route`.
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      notifyListeners();

  /// The [Navigator] removed `route`.
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      notifyListeners();

  /// The [Navigator] replaced `oldRoute` with `newRoute`.
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      notifyListeners();
}

/// Dart extension to add navigation function to a BuildContext object, e.g.
/// context.go('/');
extension GoRouterHelper on BuildContext {
  /// navigate to a location
  void go(String location) => GoRouter.of(this).go(location);

  /// Navigate to a named route.
  void goNamed(String name, [Map<String, String> params = const {}]) =>
      GoRouter.of(this).goNamed(name, params);

  /// push a location onto the page stack
  void push(String location) => GoRouter.of(this).push(location);

  /// navigate to a named route onto the page stack
  void pushNamed(String name, [Map<String, String> params = const {}]) =>
      GoRouter.of(this).pushNamed(name, params);
}

/// Page with custom transition functionality.
///
/// To be used instead of MaterialPage or CupertinoPage, which provide
/// their own transitions.
class CustomTransitionPage<T> extends Page<T> {
  /// Constructor for a page with custom transition functionality.
  ///
  /// To be used instead of MaterialPage or CupertinoPage, which provide
  /// their own transitions.
  const CustomTransitionPage({
    required this.child,
    required this.transitionsBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.maintainState = true,
    this.fullscreenDialog = false,
    this.opaque = true,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    LocalKey? key,
    String? name,
    Object? arguments,
    String? restorationId,
  }) : super(
          key: key,
          name: name,
          arguments: arguments,
          restorationId: restorationId,
        );

  /// The content to be shown in the Route created by this page.
  final Widget child;

  /// A duration argument to customize the duration of the custom page
  /// transition.
  ///
  /// Defaults to 300ms.
  final Duration transitionDuration;

  /// Whether the route should remain in memory when it is inactive.
  ///
  /// If this is true, then the route is maintained, so that any futures it is
  /// holding from the next route will properly resolve when the next route
  /// pops. If this is not necessary, this can be set to false to allow the
  /// framework to entirely discard the route's widget hierarchy when it is
  /// not visible.
  final bool maintainState;

  /// Whether this page route is a full-screen dialog.
  ///
  /// In Material and Cupertino, being fullscreen has the effects of making the
  /// app bars have a close button instead of a back button. On iOS, dialogs
  /// transitions animate differently and are also not closeable with the
  /// back swipe gesture.
  final bool fullscreenDialog;

  /// Whether the route obscures previous routes when the transition is
  /// complete.
  ///
  /// When an opaque route's entrance transition is complete, the routes
  /// behind the opaque route will not be built to save resources.
  final bool opaque;

  /// Whether you can dismiss this route by tapping the modal barrier.
  final bool barrierDismissible;

  /// The color to use for the modal barrier.
  ///
  /// If this is null, the barrier will be transparent.
  final Color? barrierColor;

  /// The semantic label used for a dismissible barrier.
  ///
  /// If the barrier is dismissible, this label will be read out if
  /// accessibility tools (like VoiceOver on iOS) focus on the barrier.
  final String? barrierLabel;

  /// Override this method to wrap the child with one or more transition
  /// widgets that define how the route arrives on and leaves the screen.
  ///
  /// By default, the child (which contains the widget returned by buildPage) is
  /// not wrapped in any transition widgets.
  ///
  /// The transitionsBuilder method, is called each time the Route's state
  /// changes while it is visible (e.g. if the value of canPop changes on the
  /// active route).
  ///
  /// The transitionsBuilder method is typically used to define transitions
  /// that animate the new topmost route's comings and goings. When the
  /// Navigator pushes a route on the top of its stack, the new route's
  /// primary animation runs from 0.0 to 1.0. When the Navigator pops the
  /// topmost route, e.g. because the use pressed the back button, the primary
  /// animation runs from 1.0 to 0.0.
  final Widget Function(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) transitionsBuilder;

  @override
  Route<T> createRoute(BuildContext context) =>
      _CustomTransitionPageRoute<T>(this);
}

class _CustomTransitionPageRoute<T> extends PageRoute<T> {
  _CustomTransitionPageRoute(CustomTransitionPage<T> page)
      : super(settings: page);

  CustomTransitionPage<T> get _page => settings as CustomTransitionPage<T>;

  @override
  Color? get barrierColor => _page.barrierColor;

  @override
  String? get barrierLabel => _page.barrierLabel;

  @override
  Duration get transitionDuration => _page.transitionDuration;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  bool get opaque => _page.opaque;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) =>
      Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        child: _page.child,
      );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      _page.transitionsBuilder(
        context,
        animation,
        secondaryAnimation,
        child,
      );
}
