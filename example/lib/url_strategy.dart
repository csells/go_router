import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shared/data.dart';
import 'shared/pages.dart';

void main() {
  // turn on the # in the URLs on the web (default)
  // GoRouter.setUrlPathStrategy(UrlPathStrategy.hash);

  // turn off the # in the URLs on the web
  // GoRouter.setUrlPathStrategy(UrlPathStrategy.path);

  runApp(App());
}

/// sample app using the path URL strategy, i.e. no # in the URL path
class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: 'URL Strategy GoRouter Example',
      );

  late final _router = GoRouter(
    routes: _routesBuilder,
    error: _errorBuilder,
    // turn off the # in the URLs on the web
    urlPathStrategy: UrlPathStrategy.path,
  );

  List<GoRoute> _routesBuilder(BuildContext context, String location) => [
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
      ];

  Page<dynamic> _errorBuilder(BuildContext context, GoRouterState state) =>
      MaterialPage<Four04Page>(
        key: const ValueKey('Four04Page'),
        child: Four04Page(message: state.error.toString()),
      );
}
