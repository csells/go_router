import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'shared/data.dart';
import 'shared/pages.dart';

void main() => runApp(App());

/// Sample class using simple declarative routes and authentication
class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  final loginInfo = LoginInfo();

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: 'GoRouter Example: Navigator Builder',
      );

  late final _router = GoRouter(
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        name: 'home',
        path: '/',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: const HomePageNoLogout(families: Families.data),
        ),
        routes: [
          GoRoute(
            name: 'family',
            path: 'family/:fid',
            pageBuilder: (context, state) {
              final family = Families.family(state.params['fid']!);
              return MaterialPage<void>(
                key: state.pageKey,
                child: FamilyPage(family: family),
              );
            },
            routes: [
              GoRoute(
                name: 'person',
                path: 'person/:pid',
                pageBuilder: (context, state) {
                  final family = Families.family(state.params['fid']!);
                  final person = family.person(state.params['pid']!);
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

    // add a wrapper around the navigator to:
    // - put loginInfo into the widget tree, and to
    // - add an overlay to show a logout option
    navigatorBuilder: (context, child) =>
        ChangeNotifierProvider<LoginInfo>.value(
      value: loginInfo,
      child: child,
      builder: (context, child) => loginInfo.loggedIn
          ? AuthOverlay(onLogout: loginInfo.logout, child: child!)
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

String _title(BuildContext context) =>
    (context as Element).findAncestorWidgetOfExactType<MaterialApp>()!.title;

class HomePageNoLogout extends StatelessWidget {
  const HomePageNoLogout({required this.families, Key? key}) : super(key: key);
  final List<Family> families;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_title(context))),
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
