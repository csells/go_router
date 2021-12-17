import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'shared/data.dart';

void main() => runApp(const App());

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  static const title = 'GoRouter Example: Redirection';

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late LoggedInState loggedInState;
  late GoRouter router;

  @override
  void initState() {
    loggedInState = LoggedInState.seeded(false);
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => HomeScreen(families: Families.data),
          routes: [
            GoRoute(
              path: 'family/:fid',
              builder: (context, state) => FamilyScreen(
                family: Families.family(state.params['fid']!),
              ),
              routes: [
                GoRoute(
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
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
      ],

      // redirect to the login page if the user is not logged in
      redirect: (state) {
        final loggedIn = loggedInState.state;
        final goingToLogin = state.location == '/login';

        // the user is not logged in and not headed to /login, they need to login
        if (!loggedIn && !goingToLogin) return '/login';

        // the user is logged in and headed to /login, no need to login again
        if (loggedIn && goingToLogin) return '/';

        // no need to redirect at all
        return null;
      },

      // changes on the listenable will cause the router to refresh it's route
      refreshListenable: GoRouterRefreshStream(loggedInState.stream),
    );
    super.initState();
  }

  // add the login info into the tree as app state that can change over time
  @override
  Widget build(BuildContext context) => Provider<LoggedInState>.value(
        value: loggedInState,
        child: MaterialApp.router(
          routeInformationParser: router.routeInformationParser,
          routerDelegate: router.routerDelegate,
          title: App.title,
          debugShowCheckedModeBanner: false,
        ),
      );

  @override
  void dispose() {
    loggedInState.dispose();
    super.dispose();
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.families,
    Key? key,
  }) : super(key: key);

  final List<Family> families;

  @override
  Widget build(BuildContext context) {
    final info = context.read<LoggedInState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(App.title),
        actions: [
          IconButton(
            onPressed: () => info.emit(false),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
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
}

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({
    required this.family,
    Key? key,
  }) : super(key: key);
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
  const PersonScreen({
    required this.family,
    required this.person,
    Key? key,
  }) : super(key: key);

  final Family family;
  final Person person;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(person.name)),
        body: Text('${person.name} ${family.name} is ${person.age} years old'),
      );
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

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
                  context.read<LoggedInState>().emit(true);
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
}
