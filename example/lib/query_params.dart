import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'shared/data.dart';
import 'shared/pages.dart';

void main() => runApp(App());

/// sample app using query parameters in the page builders
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
          title: 'Query Parameters GoRouter Example',
          debugShowCheckedModeBanner: false,
        ),
      );

  late final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => MaterialPage<HomePage>(
          key: state.pageKey,
          child: HomePage(families: Families.data),
        ),
        routes: [
          GoRoute(
            path: 'family/:fid',
            builder: (context, state) {
              final family = Families.family(state.params['fid']!);
              return MaterialPage<FamilyPage>(
                key: state.pageKey,
                child: FamilyPage(family: family),
              );
            },
            routes: [
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
          // pass the original location to the LoginPage (if there is one)
          child: LoginPage(from: state.params['from']),
        ),
      ),
    ],

    error: (context, state) => MaterialPage<ErrorPage>(
      key: state.pageKey,
      child: ErrorPage(state.error),
    ),

    // redirect to the login page if the user is not logged in
    redirect: (location) {
      final loggedIn = loginInfo.loggedIn;

      // check just the path in case there are query parameters
      final goingToLogin = Uri.parse(location).path == '/login';

      // the user is not logged in and not headed to /login, they need to login
      if (!loggedIn && !goingToLogin) return '/login?from=$location';

      // the user is logged in and headed to /login, no need to login again
      if (loggedIn && goingToLogin) return '/';

      // no need to redirect at all
      return null;
    },

    // changes on the listenable will cause the router to refresh it's route
    refreshListenable: loginInfo,
  );
}
