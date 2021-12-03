import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'shared/data.dart';

part 'named_routes.g.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  final loginInfo = LoginInfo();
  static const title = 'GoRouter Example: Named Routes';

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<LoginInfo>.value(
        value: loginInfo,
        child: MaterialApp.router(
          routeInformationParser: _router.routeInformationParser,
          routerDelegate: _router.routerDelegate,
          title: title,
          debugShowCheckedModeBanner: false,
        ),
      );

  late final _router = GoRouter(
    debugLogDiagnostics: true,
    routes: [
      homeRoute,
      loginRoute,
    ],

    // redirect to the login page if the user is not logged in
    redirect: (state) {
      final loggedIn = loginInfo.loggedIn;

      // check just the subloc in case there are query parameters
      final loginLoc = const LoginRoute().location;
      final goingToLogin = state.subloc == loginLoc;

      // the user is not logged in and not headed to /login, they need to login
      if (!loggedIn && !goingToLogin) {
        return LoginRoute(from: state.subloc).location;
      }

      // the user is logged in and headed to /login, no need to login again
      if (loggedIn && goingToLogin) return const HomeRoute().location;

      // no need to redirect at all
      return null;
    },

    // changes on the listenable will cause the router to refresh it's route
    refreshListenable: loginInfo,
  );
}

@RouteDef<HomeRoute>(
  path: '/',
  children: [
    RouteDef<FamilyRoute>(
      path: 'family/:fid',
      children: [
        RouteDef<PersonRoute>(
          path: 'person/:pid',
          children: [
            RouteDef(path: 'details/:details'),
          ],
        ),
      ],
    )
  ],
)
class HomeRoute extends GoRouteData {
  const HomeRoute();

  @override
  Widget build(BuildContext context) => HomeScreen(families: Families.data);
}

@RouteDef<LoginRoute>(
  path: '/login',
)
class LoginRoute extends GoRouteData {
  const LoginRoute({this.from, this.$extra});

  final String? from;
  final String? $extra;

  @override
  Widget build(BuildContext context) => LoginScreen(from: from);
}

class FamilyRoute extends GoRouteData {
  const FamilyRoute(this.fid);
  final String fid;

  @override
  Widget build(BuildContext context) =>
      FamilyScreen(family: Families.family(fid));
}

class PersonRoute extends GoRouteData {
  const PersonRoute(this.fid, this.pid);
  final String fid;
  final int pid;

  @override
  Widget build(BuildContext context) {
    final family = Families.family(fid);
    final person = family.person(pid);
    return PersonScreen(family: family, person: person);
  }
}

class PersonDetailsRoute extends GoRouteData {
  const PersonDetailsRoute(this.fid, this.pid, this.details);
  final String fid;
  final int pid;
  final PersonDetails details;

  @override
  Widget build(BuildContext context) {
    final family = Families.family(fid);
    final person = family.person(pid);
    return PersonDetailsPage(
      family: family,
      person: person,
      detailsKey: details,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.families, Key? key}) : super(key: key);
  final List<Family> families;

  @override
  Widget build(BuildContext context) {
    final info = context.read<LoginInfo>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(App.title),
        actions: [
          IconButton(
            onPressed: info.logout,
            tooltip: 'Logout: ${info.userName}',
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: ListView(
        children: [
          for (final f in families)
            ListTile(
              title: Text(f.name),
              onTap: () => FamilyRoute(f.id).go(context),
            )
        ],
      ),
    );
  }
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
                onTap: () => PersonRoute(family.id, p.id).go(context),
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
        body: ListView(
          children: [
            ListTile(
              title: Text(
                  '${person.name} ${family.name} is ${person.age} years old'),
            ),
            for (var entry in person.details.entries)
              ListTile(
                title: Text('${entry.key.name} - ${entry.value}'),
                onTap: () => PersonDetailsRoute(family.id, person.id, entry.key)
                    .go(context),
              )
          ],
        ),
      );
}

class PersonDetailsPage extends StatelessWidget {
  const PersonDetailsPage({
    required this.family,
    required this.person,
    required this.detailsKey,
    Key? key,
  }) : super(key: key);

  final Family family;
  final Person person;
  final PersonDetails detailsKey;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(person.name)),
        body: ListView(
          children: [
            ListTile(
                title: Text(
              '${person.name} ${family.name}: '
              '$detailsKey - ${person.details[detailsKey]}',
            ))
          ],
        ),
      );
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({this.from, Key? key}) : super(key: key);
  final String? from;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(App.title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  // log a user in, letting all the listeners know
                  context.read<LoginInfo>().login('test-user');

                  // if there's a deep link, go there
                  if (from != null) context.go(from!);
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
}
