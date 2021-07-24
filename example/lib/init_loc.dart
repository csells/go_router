import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shared/pages.dart';

void main() => runApp(App());

/// sample class using simple declarative routes
class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: 'Initial Location GoRouter Example',
      );

  late final _router = GoRouter(
    routes: _routesBuilder,
    error: _errorBuilder,
    initialLocation: '/page2',
  );
  List<GoRoute> _routesBuilder(BuildContext context, String location) => [
        GoRoute(
          pattern: '/',
          builder: (context, state) => const MaterialPage<Page1Page>(
            key: ValueKey('Page1Page'),
            child: Page1Page(),
          ),
        ),
        GoRoute(
          pattern: '/page2',
          builder: (context, state) => const MaterialPage<Page2Page>(
            key: ValueKey('Page2Page'),
            child: Page2Page(),
          ),
        ),
        GoRoute(
          pattern: '/page3',
          builder: (context, state) => const MaterialPage<Page3Page>(
            key: ValueKey('Page3Page'),
            child: Page3Page(),
          ),
        ),
      ];

  Page<dynamic> _errorBuilder(BuildContext context, GoRouterState state) =>
      MaterialPage<ErrorPage>(
        key: const ValueKey('ErrorPage'),
        child: ErrorPage(message: state.error.toString()),
      );
}
