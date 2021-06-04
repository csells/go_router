import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shared/data.dart';
import 'shared/pages.dart';

void main() {
  // turn on the # in the URLs on the web (default)
  // GoRouter.setUrlPathStrategy(UrlPathStrategy.hash);

  // turn off the # in the URLs on the web
  GoRouter.setUrlPathStrategy(UrlPathStrategy.path);

  runApp(App());
}

class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: 'URL Strategy GoRouter Example',
      );

  final _router = GoRouter.routes(
    builder: (context, location) => [
      GoRoute(
        pattern: '/',
        builder: (context, args) => MaterialPage<FamiliesPage>(
          key: const ValueKey('FamiliesPage'),
          child: FamiliesPage(families: Families.data),
        ),
      ),
      GoRoute(
        pattern: '/family/:fid',
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
        builder: (context, args) {
          final family = Families.family(args['fid']!);
          final person = family.person(args['pid']!);

          return MaterialPage<PersonPage>(
            key: ValueKey(person),
            child: PersonPage(family: family, person: person),
          );
        },
      ),
    ],
    error: (context, location, ex) => MaterialPage<Four04Page>(
      key: const ValueKey('ErrorPage'),
      child: Four04Page(message: ex.toString()),
    ),
  );
}
