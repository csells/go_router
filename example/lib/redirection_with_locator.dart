import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'shared/data.dart';
import 'shared/pages.dart';

final loginInfo = LoginInfo();

void main() => runApp(
      ChangeNotifierProvider.value(
        value: loginInfo,
        child: const App(),
      ),
    );

/// sample app using a locator to redirect to another location
class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: 'GoRouter Example: Redirection with Locator',
        debugShowCheckedModeBanner: false,
      );

  late final _router = GoRouter(
    locator: context.read,
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: HomePage(families: Families.data),
        ),
        routes: [
          GoRoute(
            path: 'family/:fid',
            pageBuilder: (context, state) {
              final family = Families.family(state.params['fid']!);
              return MaterialPage<void>(
                key: state.pageKey,
                child: FamilyPage(family: family),
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
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: const LoginPage(),
        ),
      ),
    ],

    errorPageBuilder: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      child: ErrorPage(state.error),
    ),

    // redirect to the login page if the user is not logged in
    redirect: (state) {
      final locator = state.locator;
      if (locator != null) {
        final loginInfo = locator<LoginInfo>();
        final loggedIn = loginInfo.loggedIn;
        final goingToLogin = state.location == '/login';

        // the user is not logged in and not headed to /login, they need to login
        if (!loggedIn && !goingToLogin) return '/login';

        // the user is logged in and headed to /login, no need to login again
        if (loggedIn && goingToLogin) return '/';

        // no need to redirect at all
        return null;
      }
    },

    // changes on the listenable will cause the router to refresh it's route
    refreshListenable: loginInfo,
  );
}
