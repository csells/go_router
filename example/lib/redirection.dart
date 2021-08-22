import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'shared/data.dart';
import 'shared/pages.dart';

void main() => runApp(App());

/// sample app using redirection to another location
class App extends StatelessWidget {
  final loginInfo = LoginInfo();
  App({Key? key}) : super(key: key);

  // add the login info into the tree as app state that can change over time
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<LoginInfo>.value(
        value: loginInfo,
        child: MaterialApp.router(
          routeInformationParser: _router.routeInformationParser,
          routerDelegate: _router.routerDelegate,
          title: 'Redirection GoRouter Example',
          debugShowCheckedModeBanner: false,
        ),
      );

  late final _router = GoRouter(
    routes: _routesBuilder,
    error: _errorBuilder,

    // the guard checks if the user is logged in via the GoRouterLoggedIn mixin
    refreshListenable: GoRouterLoginGuard(loginInfo, loginPath: '/login'),
  );

  List<GoRoute> _routesBuilder(BuildContext context, String location) => [
        GoRoute(
          path: '/',
          builder: (context, state) => MaterialPage<HomePage>(
            key: state.pageKey,
            child: HomePage(families: Families.data),
          ),
          stacked: [
            GoRoute(
              path: 'family/:fid',
              builder: (context, state) {
                final family = Families.family(state.params['fid']!);
                return MaterialPage<FamilyPage>(
                  key: state.pageKey,
                  child: FamilyPage(family: family),
                );
              },
              stacked: [
                GoRoute(
                  path: 'person/:pid',
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
        GoRoute(
          path: '/login',
          builder: (context, state) => MaterialPage<LoginPage>(
            key: state.pageKey,
            child: const LoginPage(),
          ),
        ),
      ];

  Page<dynamic> _errorBuilder(BuildContext context, GoRouterState state) =>
      MaterialPage<ErrorPage>(
        key: state.pageKey,
        child: ErrorPage(state.error),
      );
}
