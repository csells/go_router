import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'shared/data.dart';

void main() => runApp(App());

/// sample app using query parameters in the page builders
class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  final loginInfo = LoginInfo();

  // add the login info into the tree as app state that can change over time
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<LoginInfo>.value(
        value: loginInfo,
        child: MaterialApp.router(
          routeInformationParser: _router.routeInformationParser,
          routerDelegate: _router.routerDelegate,
          title: 'GoRouter Example: Extra Parameter',
          debugShowCheckedModeBanner: false,
        ),
      );

  late final _router = GoRouter(
    routes: [
      GoRoute(
        name: 'home',
        path: '/',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: HomePage(families: Families.data),
        ),
        routes: [
          GoRoute(
            name: 'family',
            path: 'family',
            pageBuilder: (context, state) {
              final params = state.extra! as Map<String, Object>;
              final family = params['family']! as Family;
              return MaterialPage<void>(
                key: state.pageKey,
                child: FamilyPage(family: family),
              );
            },
            routes: [
              GoRoute(
                name: 'person',
                path: 'person',
                pageBuilder: (context, state) {
                  final params = state.extra! as Map<String, Object>;
                  final family = params['family']! as Family;
                  final person = params['person']! as Person;
                  return MaterialPage<void>(
                    key: state.pageKey,
                    child: PersonPage(family: family, person: person),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        name: 'login',
        path: '/login',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          // pass the original location to the LoginPage (if there is one)
          child: LoginPage(from: state.queryParams['from']),
        ),
      ),
    ],

    errorPageBuilder: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      child: ErrorPage(state.error),
    ),

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
  );
}

String _title(BuildContext context) =>
    (context as Element).findAncestorWidgetOfExactType<MaterialApp>()!.title;

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
              onTap: () => context.goNamed('family', extra: {'family': f}),
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
              SelectableText(error?.toString() ?? 'page not found'),
              TextButton(
                onPressed: () => context.goNamed('home'),
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
