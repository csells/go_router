import 'dart:html';

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'shared/data.dart';

import 'shared/pages.dart';

void main() => runApp(App());

/// sample class using simple declarative routes
class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: 'Nested Routes GoRouter Example',
      );

  late final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        redirect: (location) => '/family/${Families.data[0].id}',
      ),
      GoRoute(
        path: '/family/:fid',
        builder: (context, state) {
          final fid = state.params['fid']!;
          final family = Families.data.firstWhere((f) => f.id == fid,
              orElse: () => throw Exception('family not found: $fid'));

          return MaterialPage<void>(
            key: state.pageKey,
            child: FamilyTabsPage(key: state.pageKey, currentFamily: family),
          );
        },
      ),
    ],
    error: _errorBuilder,
  );

  Page<dynamic> _errorBuilder(BuildContext context, GoRouterState state) =>
      MaterialPage<ErrorPage>(
        key: state.pageKey,
        child: ErrorPage(state.error),
      );
}
