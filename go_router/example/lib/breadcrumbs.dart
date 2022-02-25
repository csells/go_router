import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shared/data.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  static const title = 'GoRouter Example: Breadcrumbs';

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
        name: 'Home',
        builder: (context, state) => HomeScreen(families: Families.data),
        routes: [
          GoRoute(
            name: 'Family',
            path: 'family/:fid',
            builder: (context, state) => FamilyScreen(
              family: Families.family(state.params['fid']!),
            ),
            routes: [
              GoRoute(
                name: 'Person',
                path: 'person/:pid',
                builder: (context, state) {
                  final family = Families.family(state.params['fid']!);
                  final person = family.person(state.params['pid']!);

                  return PersonScreen(family: family, person: person);
                },
              ),
            ],
          ),
        ],
      ),
    ],
    navigatorBuilder: (context, child) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BreadCrumbs(router: _router),
        if (child != null)
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: child,
            ),
          ),
      ],
    ),
  );
}

class BreadCrumbs extends StatelessWidget {
  const BreadCrumbs({
    required this.router,
    Key? key,
  }) : super(key: key);

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    // ignore: invalid_use_of_visible_for_testing_member
    final matches = router.routerDelegate.matches;
    return Container(
      height: 100,
      alignment: Alignment.centerLeft,
      color: Colors.black,
      child: SafeArea(
        bottom: false,
        child: Material(
          color: Colors.transparent,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                for (final match in matches) ...[
                  const Icon(
                    Icons.arrow_right_outlined,
                    color: Colors.white,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: ActionChip(
                      label: Text(
                        match.route.name ?? 'Hey',
                        style: TextStyle(
                          color: matches.last == match
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                      backgroundColor:
                          matches.last == match ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: const BorderSide(color: Colors.white)),
                      onPressed: () {
                        if (matches.last == match) return;
                        router.navigator!.popUntil(
                          (route) => route.settings.name == match.route.name,
                        );
                      },
                    ),
                  ),
                ]
              ].skip(1).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.families, Key? key}) : super(key: key);
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

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({required this.family, Key? key}) : super(key: key);
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

class PersonScreen extends StatelessWidget {
  const PersonScreen({required this.family, required this.person, Key? key})
      : super(key: key);

  final Family family;
  final Person person;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(person.name)),
        body: Text('${person.name} ${family.name} is ${person.age} years old'),
      );
}
