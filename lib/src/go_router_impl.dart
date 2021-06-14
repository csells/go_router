import 'package:flutter/widgets.dart';
import '../go_router.dart';

/// GoRouter implementation of the RouterDelegate base class
class GoRouterDelegate extends RouterDelegate<Uri>
    with
        PopNavigatorRouterDelegateMixin<Uri>,
        // ignore: prefer_mixin
        ChangeNotifier {
  Uri _loc;
  final _key = GlobalKey<NavigatorState>();
  final GoRouteBuilder builder;

  GoRouterDelegate({required this.builder, Uri? initialLocation})
      : _loc = initialLocation ?? Uri();

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

/// a marker type indicating a redirection instead of an actual page
class GoRedirect extends Page<dynamic> {
  /// the location to redirect to
  final String location;

  /// ctor
  const GoRedirect(this.location);

  /// not implemented; should never be called
  @override
  Route createRoute(BuildContext context) => throw UnimplementedError();
}

/// GoRouter implementation of InheritedWidget for purposes of finding the
/// current GoRouter in the widget tree. This is useful when routing from
/// anywhere in your app.
class InheritedGoRouter extends InheritedWidget {
  final GoRouter goRouter;
  const InheritedGoRouter(
      {required Widget child, required this.goRouter, Key? key})
      : super(child: child, key: key);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;
}
