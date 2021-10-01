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
        title: 'Nested Navigation GoRouter Example',
      );

  late final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        redirect: (_) => '/family/${Families.data[0].id}',
      ),
      GoRoute(
        path: '/family/:fid',
        pageBuilder: (context, state) {
          final family = Families.family(state.params['fid']!);

          return MaterialPage<void>(
            key: state.pageKey,
            child: FamilyTabsPage(key: state.pageKey, selectedFamily: family),
          );
        },
        routes: [
          GoRoute(
            path: 'person/:pid',
            pageBuilder: (context, state) {
              final family = Families.family(state.params['fid']!);
              final person = family.person(state.params['pid']!);

              return MaterialPage<void>(
                key: state.pageKey,
                child: PersonPage(family: family, person: person),
              );
            },
          ),
        ],
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      child: ErrorPage(state.error),
    ),
  );
}
