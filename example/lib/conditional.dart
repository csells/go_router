import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'shared/data.dart';
import 'shared/pages.dart';

void main() => runApp(App());

/// sample app using conditional routes
class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  // add the login info into the tree as app state that can change over time
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<LoginInfo>(
        create: (context) => LoginInfo(),
        child: MaterialApp.router(
          routeInformationParser: _router.routeInformationParser,
          routerDelegate: _router.routerDelegate,
          title: 'Conditional Routes GoRouter Example',
          debugShowCheckedModeBanner: false,
        ),
      );

  late final _router = GoRouter(routes: _routeBuilder, error: _errorBuilder);

  // the routes when the user is logged in
  final _loggedInRoutes = [
    GoRoute(
      pattern: '/',
      builder: (context, state) => MaterialPage<HomePage>(
        key: state.pageKey,
        child: HomePage(families: Families.data),
      ),
      routes: [
        GoRoute(
          pattern: 'family/:fid',
          builder: (context, state) {
            final family = Families.family(state.params['fid']!);

            return MaterialPage<FamilyPage>(
              key: state.pageKey,
              child: FamilyPage(family: family),
            );
          },
          routes: [
            GoRoute(
              pattern: 'person/:pid',
              builder: (context, state) {
                final family = Families.family(state.params['fid']!);
                final person = family.person(state.params['pid']!);

                return MaterialPage<PersonPage>(
                  key: state.pageKey,
                  child: PersonPage(family: family, person: person),
                );
              },
            ),
          ],
        ),
      ],
    ),
  ];

  // the routes when the user is not logged in
  final _loggedOutRoutes = [
    GoRoute(
      pattern: '/',
      builder: (context, state) => MaterialPage<LoginPage>(
        key: state.pageKey,
        child: const LoginPage(),
      ),
    ),
  ];

  // changes in the login info will rebuild the stack of routes
  List<GoRoute> _routeBuilder(BuildContext context, String location) =>
      context.watch<LoginInfo>().loggedIn ? _loggedInRoutes : _loggedOutRoutes;

  Page<dynamic> _errorBuilder(BuildContext context, GoRouterState state) =>
      MaterialPage<ErrorPage>(
        key: state.pageKey,
        child: ErrorPage(state.error),
      );
}
