import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'shared/data.dart';
import 'shared/pages.dart';

void main() => runApp(App());

/// sample app using redirection to another location
class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  // add the login info into the tree as app state that can change over time
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<LoginInfo>(
        create: (context) => LoginInfo(),
        child: MaterialApp.router(
          routeInformationParser: _router.routeInformationParser,
          routerDelegate: _router.routerDelegate,
          title: 'Redirection GoRouter Example',
          debugShowCheckedModeBanner: false,
        ),
      );

  late final _router = GoRouter(routes: _routesBuilder, error: _errorBuilder);

  List<GoRoute> _routesBuilder(BuildContext context, String location) => [
        GoRoute(
          pattern: '/',
          redirect: (context, args) => _redirectToLogin(context),
          builder: (context, args) => MaterialPage<FamiliesPage>(
            key: const ValueKey('FamiliesPage'),
            child: FamiliesPage(families: Families.data),
          ),
        ),
        GoRoute(
          pattern: '/family/:fid',
          redirect: (context, args) => _redirectToLogin(context),
          builder: (context, args) {
            final family = Families.family(args['fid']!);
            return MaterialPage<FamilyPage>(
              key: ValueKey(family),
              child: FamilyPage(family: family),
            );
          },
        ),
        GoRoute(
          pattern: '/family/:fid/person/:pid',
          redirect: (context, args) => _redirectToLogin(context),
          builder: (context, args) {
            final family = Families.family(args['fid']!);
            final person = family.person(args['pid']!);
            return MaterialPage<PersonPage>(
              key: ValueKey(person),
              child: PersonPage(family: family, person: person),
            );
          },
        ),
        GoRoute(
          pattern: '/login',
          redirect: (context, args) => _redirectToHome(context),
          builder: (context, args) => const MaterialPage<LoginPage>(
            key: ValueKey('LoginPage'),
            child: LoginPage(),
          ),
        ),
      ];

  // if the user is not logged in, redirect to /login
  String? _redirectToLogin(BuildContext context) =>
      context.watch<LoginInfo>().loggedIn ? null : '/login';

  // if the user is logged in, no need to login again, so redirect to /
  String? _redirectToHome(BuildContext context) =>
      context.watch<LoginInfo>().loggedIn ? '/' : null;

  Page<dynamic> _errorBuilder(BuildContext context, GoRouteException ex) =>
      MaterialPage<Four04Page>(
        key: const ValueKey('Four04Page'),
        child: Four04Page(message: ex.nested.toString()),
      );
}
