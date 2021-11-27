import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shared/data.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  static const title = 'GoRouter Example: Async Data';
  final repo = Repository();

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: title,
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
              if (snapshot.hasError) {
                throw snapshot.error! is Exception
                    ? snapshot.error! as Exception
                    : Exception(snapshot.error);
              }

              if (snapshot.hasData) {
                return HomePage(families: snapshot.data!);
              }

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
                  if (snapshot.hasError) {
                    throw snapshot.error! is Exception
                        ? snapshot.error! as Exception
                        : Exception(snapshot.error);
                  }

                  if (snapshot.hasData) {
                    return FamilyPage(family: snapshot.data!);
                  }

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
                      if (snapshot.hasError) {
                        throw snapshot.error! is Exception
                            ? snapshot.error! as Exception
                            : Exception(snapshot.error);
                      }

                      if (snapshot.hasData) {
                        return PersonPage(
                            family: snapshot.data!.family,
                            person: snapshot.data!.person);
                      }

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
  );
}

class HomePage extends StatelessWidget {
  const HomePage({required this.families, Key? key}) : super(key: key);
  final List<Family> families;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(App.title)),
        body: ListView(
          children: [
            for (final f in families)
              ListTile(
                title: Text(f.name),
                onTap: () => context.go('/family/${f.id}'),
              )
          ],
        ),
      );
}

class FamilyPage extends StatelessWidget {
  const FamilyPage({required this.family, Key? key}) : super(key: key);
  final Family family;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(family.name)),
        body: ListView(
          children: [
            for (final p in family.people)
              ListTile(
                title: Text(p.name),
                onTap: () => context.go('/family/${family.id}/person/${p.id}'),
              ),
          ],
        ),
      );
}

class PersonPage extends StatelessWidget {
  const PersonPage({required this.family, required this.person, Key? key})
      : super(key: key);

  final Family family;
  final Person person;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(person.name)),
        body: Text('${person.name} ${family.name} is ${person.age} years old'),
      );
}
