import 'package:flutter/widgets.dart';
import '../go_router.dart';

/// GoRouter implementation of the RouterDelegate base class
class GoRouterDelegate extends RouterDelegate<Uri>
    with
        PopNavigatorRouterDelegateMixin<Uri>,
        // ignore: prefer_mixin
        ChangeNotifier {
  var _loc = Uri();
  final _key = GlobalKey<NavigatorState>();
  final GoRouterWidgetBuilder builder;

  GoRouterDelegate({required this.builder, Uri? initialLocation}) {
    // fix for https://github.com/csells/go_router/issues/12 (WTF?)
    if (initialLocation != null && initialLocation.path != '/') {
      _loc = initialLocation;
    }
  }

  @override
  GlobalKey<NavigatorState> get navigatorKey => _key;

  @override
  Uri get currentConfiguration => _loc;

  void go(String route) {
    _loc = Uri.parse(route);
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) =>
      builder(context, _loc.toString().trim());

  @override
  Future<void> setNewRoutePath(Uri configuration) async {
    _loc = configuration;
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
  final String loc;
  final Map<String, String> params;
  GoRouteMatch(this.route, this.loc, this.params);

  static GoRouteMatch? match(GoRoute route, String location) {
    final match = route.matchPatternAsPrefix(location);
    if (match == null) return null;
    final params = route.extractPatternParams(match);
    final subloc = GoRouter.locationFor(route.pattern, params);
    return GoRouteMatch(route, subloc, params);
  }
}