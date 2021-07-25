import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shared/pages.dart';

void main() {
  // turn on the # in the URLs on the web (default)
  // GoRouter.setUrlPathStrategy(UrlPathStrategy.hash);

  // turn off the # in the URLs on the web
  // GoRouter.setUrlPathStrategy(UrlPathStrategy.path);

  runApp(App());
}

/// sample class using simple declarative routes
class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: 'URL Path Strategy GoRouter Example',
      );

  late final _router = GoRouter(
    routes: _routesBuilder,
    error: _errorBuilder,
    // turn off the # in the URLs on the web
    urlPathStrategy: UrlPathStrategy.path,
  );

  List<GoRoute> _routesBuilder(BuildContext context, String location) => [
        GoRoute(
          pattern: '/',
          builder: (context, state) => MaterialPage<Page1Page>(
            key: state.pageKey,
            child: const Page1Page(),
          ),
        ),
        GoRoute(
          pattern: '/page2',
          builder: (context, state) => MaterialPage<Page2Page>(
            key: state.pageKey,
            child: const Page2Page(),
          ),
        ),
      ];

  Page<dynamic> _errorBuilder(BuildContext context, GoRouterState state) =>
      MaterialPage<ErrorPage>(
        key: state.pageKey,
        child: ErrorPage(state.error),
      );
}
