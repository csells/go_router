import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shared/data.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  // TODO: doesn't work w/ the back button : (
  static const title = 'GoRouter Example: Extra Parameter';

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: title,
      );

  late final _router = GoRouter(
    routes: [
      GoRoute(
        name: 'home',
        path: '/',
        builder: (context, state) => HomePage(families: Families.data),
        routes: [
          GoRoute(
            name: 'family',
            path: 'family',
            builder: (context, state) {
              final params = state.extra! as Map<String, Object>;
              final family = params['family']! as Family;
              return FamilyPage(family: family);
            },
            routes: [
              GoRoute(
                name: 'person',
                path: 'person',
                builder: (context, state) {
                  final params = state.extra! as Map<String, Object>;
                  final family = params['family']! as Family;
                  final person = params['person']! as Person;
                  return PersonPage(family: family, person: person);
                },
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
                onTap: () => context.goNamed('family', extra: {'family': f}),
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
                onTap: () => context.go(
                  context.namedLocation('person'),
                  extra: {'family': family, 'person': p},
                ),
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
