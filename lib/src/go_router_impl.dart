import 'package:flutter/widgets.dart';
import '../go_router.dart';

class GoRouterDelegate extends RouterDelegate<Uri>
    with
        PopNavigatorRouterDelegateMixin<Uri>,
        // ignore: prefer_mixin
        ChangeNotifier {
  Uri _loc = Uri.parse('/');
  final _key = GlobalKey<NavigatorState>();
  final GoRouteBuilder builder;

  GoRouterDelegate({required this.builder});

  @override
  GlobalKey<NavigatorState> get navigatorKey => _key;

  @override
  Uri get currentConfiguration => _loc;

  void go(String route) {
    _loc = Uri.parse(route);
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) => builder(context, _loc.toString().trim());

  @override
  Future<void> setNewRoutePath(Uri configuration) async {
    _loc = configuration;
  }
}

class GoRouteInformationParser extends RouteInformationParser<Uri> {
  @override
  Future<Uri> parseRouteInformation(RouteInformation routeInformation) async =>
      Uri.parse(routeInformation.location ?? '/');

  @override
  RouteInformation restoreRouteInformation(Uri configuration) => RouteInformation(location: configuration.toString());
}

class InheritedGoRouter extends InheritedWidget {
  final GoRouter goRouter;
  const InheritedGoRouter({required Widget child, required this.goRouter, Key? key}) : super(child: child, key: key);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;
}

