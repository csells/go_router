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
        title: 'Declarative Routes GoRouter Example',
      );

  late final _router = GoRouter(routes: _routesBuilder, error: _errorBuilder);
  List<GoRoute> _routesBuilder(BuildContext context, String location) => [
        GoRoute(
          pattern: '/',
          builder: (context, state) => const MaterialPage<HomePage>(
            key: ValueKey('HomePage'),
            child: HomePage(),
          ),
        ),
        GoRoute(
          pattern: '/page2',
          builder: (context, state) => const MaterialPage<Page2Page>(
            key: ValueKey('Page2Page'),
            child: Page2Page(),
          ),
        ),
      ];

  Page<dynamic> _errorBuilder(BuildContext context, GoRouterState state) =>
      MaterialPage<Four04Page>(
        key: const ValueKey('Four04Page'),
        child: Four04Page(message: state.error.toString()),
      );
}
