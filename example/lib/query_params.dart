import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'shared/data.dart';
import 'shared/pages.dart';

void main() => runApp(App());

/// sample app using query parameters in the page builders
class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  // add the login info into the tree as app state that can change over time
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<LoginInfo>(
        create: (context) => LoginInfo(),
        child: MaterialApp.router(
          routeInformationParser: _router.routeInformationParser,
          routerDelegate: _router.routerDelegate,
          title: 'Query Parameters GoRouter Example',
          debugShowCheckedModeBanner: false,
        ),
      );

  late final _router = GoRouter(
    routes: _routeBuilder,
    error: _errorBuilder,
    redirect: _redirect,
  );

  List<GoRoute> _routeBuilder(BuildContext context, String location) => [
        GoRoute(
          pattern: '/',
          builder: (context, state) => MaterialPage<FamiliesPage>(
            key: const ValueKey('FamiliesPage'),
            child: FamiliesPage(families: Families.data),
          ),
        ),
        GoRoute(
          pattern: '/family/:fid',
          builder: (context, state) {
            final family = Families.family(state.params['fid']!);
            return MaterialPage<FamilyPage>(
              key: ValueKey(family),
              child: FamilyPage(family: family),
            );
          },
        ),
        GoRoute(
          pattern: '/family/:fid/person/:pid',
          builder: (context, state) {
            final family = Families.family(state.params['fid']!);
            final person = family.person(state.params['pid']!);
            return MaterialPage<PersonPage>(
              key: ValueKey(person),
              child: PersonPage(family: family, person: person),
            );
          },
        ),
        GoRoute(
          pattern: '/login',
          builder: (context, state) => MaterialPage<LoginPage>(
            key: const ValueKey('LoginPage'),
            child: LoginPage(from: state.params['from']),
          ),
        ),
      ];

  // redirect based on app and routing state
  String? _redirect(BuildContext context, String location) {
    // watching LoginInfo will cause a change in LoginInfo to trigger routing
    final loggedIn = context.watch<LoginInfo>().loggedIn;
    final loc = Uri.parse(location).path;
    final goingToLogin = loc == '/login';

    // the user is not logged in and not headed to /login, they need to login
    if (!loggedIn && !goingToLogin) return '/login?from=$loc';

    // the user is logged in and headed to /login, no need to login again
    if (loggedIn && goingToLogin) return '/';

    // no need to redirect at all
    return null;
  }

  Page<dynamic> _errorBuilder(BuildContext context, GoRouterState state) =>
      MaterialPage<Four04Page>(
        key: const ValueKey('Four04Page'),
        child: Four04Page(message: state.error.toString()),
      );
}
