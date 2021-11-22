import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'shared/data.dart';

part 'named_routes.g.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  final loginInfo = LoginInfo();

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<LoginInfo>.value(
        value: loginInfo,
        child: MaterialApp.router(
          routeInformationParser: _router.routeInformationParser,
          routerDelegate: _router.routerDelegate,
          title: 'GoRouter Example: Named Routes',
          debugShowCheckedModeBanner: false,
        ),
      );

  late final _router = GoRouter(
    debugLogDiagnostics: true,
    routes: [
      homeRoute,
      loginRoute,
    ],

    errorPageBuilder: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      child: ErrorPage(state.error),
    ),

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

String _title(BuildContext context) =>
    (context as Element).findAncestorWidgetOfExactType<MaterialApp>()!.title;

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
  Widget build(BuildContext context) => HomePage(families: Families.data);
}

@RouteDef<LoginRoute>(
  path: '/login',
)
class LoginRoute extends GoRouteData {
  const LoginRoute({this.from, this.$extra});

  final String? from;
  final String? $extra;

  @override
  Widget build(BuildContext context) => LoginPage(from: from);
}

class FamilyRoute extends GoRouteData {
  const FamilyRoute(this.fid);
  final String fid;

  @override
  Widget build(BuildContext context) =>
      FamilyPage(family: Families.family(fid));
}

class PersonRoute extends GoRouteData {
  const PersonRoute(this.fid, this.pid);
  final String fid;
  final int pid;

  @override
  Widget build(BuildContext context) {
    final family = Families.family(fid);
    final person = family.person(pid);
    return PersonPage(family: family, person: person);
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

class HomePage extends StatelessWidget {
  const HomePage({required this.families, Key? key}) : super(key: key);
  final List<Family> families;

  @override
  Widget build(BuildContext context) {
    final info = _info(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title(context)),
        actions: [
          if (info != null)
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

  LoginInfo? _info(BuildContext context) {
    try {
      return context.read<LoginInfo>();
    } on Exception catch (_) {
      return null;
    }
  }
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
                onTap: () => PersonRoute(family.id, p.id).go(context),
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

class ErrorPage extends StatelessWidget {
  const ErrorPage(this.error, {Key? key}) : super(key: key);
  final Exception? error;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error?.toString() ?? 'page not found'),
              TextButton(
                onPressed: () => const HomeRoute().go(context),
                child: const Text('Home'),
              ),
            ],
          ),
        ),
      );
}

class LoginPage extends StatelessWidget {
  const LoginPage({this.from, Key? key}) : super(key: key);
  final String? from;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_title(context))),
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
