import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'shared/data.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  final loginInfo = LoginInfo();
  static const title = 'GoRouter Example: Navigator Builder';

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: title,
      );

  late final _router = GoRouter(
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        name: 'home',
        path: '/',
        builder: (context, state) =>
            HomeScreenNoLogout(families: Families.data),
        routes: [
          GoRoute(
            name: 'family',
            path: 'family/:fid',
            builder: (context, state) {
              final family = Families.family(state.params['fid']!);
              return FamilyScreen(family: family);
            },
            routes: [
              GoRoute(
                name: 'person',
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
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (context, state) =>
            // pass the original location to the LoginPage (if there is one)
            LoginScreen(from: state.queryParams['from']),
      ),
    ],

    // redirect to the login page if the user is not logged in
    redirect: (state) {
      final loggedIn = loginInfo.loggedIn;

      // check just the subloc in case there are query parameters
      final loginLoc = state.namedLocation('login');
      final goingToLogin = state.subloc == loginLoc;

      // the user is not logged in and not headed to /login, they need to login
      if (!loggedIn && !goingToLogin) {
        return state.namedLocation(
          'login',
          queryParams: {'from': state.subloc},
        );
      }

      // the user is logged in and headed to /login, no need to login again
      if (loggedIn && goingToLogin) return state.namedLocation('home');

      // no need to redirect at all
      return null;
    },

    // changes on the listenable will cause the router to refresh it's route
    refreshListenable: loginInfo,

    // add a wrapper around the navigator to:
    // - put loginInfo into the widget tree, and to
    // - add an overlay to show a logout option
    navigatorBuilder: (context, child) =>
        ChangeNotifierProvider<LoginInfo>.value(
      value: loginInfo,
      child: child,
      builder: (context, child) => loginInfo.loggedIn
          ? AuthOverlay(
              onLogout: () {
                loginInfo.logout();
                _router.goNamed('home'); // clear out the `from` query param
              },
              child: child!)
          : child!,
    ),
  );
}

// A simple class for placing an exit button on top of all screens
class AuthOverlay extends StatelessWidget {
  const AuthOverlay({
    required this.onLogout,
    required this.child,
    Key? key,
  }) : super(key: key);

  final Widget child;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          child,
          Positioned(
            top: 90,
            right: 4,
            child: ElevatedButton(
              onPressed: onLogout,
              child: const Icon(Icons.logout),
            ),
          ),
        ],
      );
}

class HomeScreenNoLogout extends StatelessWidget {
  const HomeScreenNoLogout({required this.families, Key? key})
      : super(key: key);
  final List<Family> families;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(App.title)),
        body: ListView(
          children: [
            for (final f in families)
              ListTile(
                title: Text(f.name),
                onTap: () => context.goNamed('family', params: {'fid': f.id}),
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
