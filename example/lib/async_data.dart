import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shared/data.dart';
import 'shared/pages.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  final repo = Repository();

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: 'Async Data GoRouter Example',
      );

  late final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: FutureBuilder<List<Family>>(
            future: repo.getFamilies(),
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return ErrorPage(snapshot.error as Exception?);
              if (snapshot.hasData) return HomePage(families: snapshot.data!);
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
        routes: [
          GoRoute(
            path: 'family/:fid',
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: FutureBuilder<Family>(
                future: repo.getFamily(state.params['fid']!),
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return ErrorPage(snapshot.error as Exception?);
                  if (snapshot.hasData)
                    return FamilyPage(family: snapshot.data!);
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
            routes: [
              GoRoute(
                path: 'person/:pid',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: state.pageKey,
                  child: FutureBuilder<FamilyPerson>(
                    future: repo.getPerson(
                      state.params['fid']!,
                      state.params['pid']!,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasError)
                        return ErrorPage(snapshot.error as Exception?);
                      if (snapshot.hasData)
                        return PersonPage(
                            family: snapshot.data!.family,
                            person: snapshot.data!.person);
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ),
            ],
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

class NoTransitionPage<T> extends CustomTransitionPage<T> {
  const NoTransitionPage({required Widget child, LocalKey? key})
      : super(transitionsBuilder: _transitionsBuilder, child: child, key: key);

  static Widget _transitionsBuilder(
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child) =>
      child;
}
