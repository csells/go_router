import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shared/pages.dart';

void main() => runApp(App());

/// Sample class using simple declarative routes and authentication
class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  // Simple simulation of storing authentication state.
  static ValueNotifier<bool> signedIn = ValueNotifier(false);

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: 'Authentication Example',
      );

  final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: const Page1Page(),
        ),
      ),
      GoRoute(
        path: '/page2',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: const Page2Page(),
        ),
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      child: ErrorPage(state.error),
    ),

    // A wrapper around the navigator to implement
    // login and registration screens.
    navigatorBuilder: (context, child) => ValueListenableBuilder<bool>(
      valueListenable: signedIn,
      child: child,
      builder: (context, signedInValue, child) => signedInValue
          ? AuthOverlay(
              child: child,
              onLogout: () {
                signedIn.value = false;
              },
            )
          : const InnerRouter(child: AuthScreen()),
    ),
  );
}

// A simple class for placing an exit button on top of all screens
// (to simplify the example code).
class AuthOverlay extends StatelessWidget {
  const AuthOverlay({
    required this.onLogout,
    this.child,
    Key? key,
  }) : super(key: key);

  final Widget? child;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          if (child != null) child!,
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

// Nested router to provide navigation between screens
// during login and registration.
class InnerRouter extends StatefulWidget {
  const InnerRouter({
    required this.child,
    Key? key,
  }) : super(key: key);

  final Widget child;

  @override
  _InnerRouterState createState() => _InnerRouterState();
}

class _InnerRouterState extends State<InnerRouter> {
  late final RouterDelegate _routerDelegate = _InnerRouterDelegate(
    widget.child,
  );
  ChildBackButtonDispatcher? _backButtonDispatcher;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Defer back button dispatching to the child router
    _backButtonDispatcher = Router.of(context)
        .backButtonDispatcher
        ?.createChildBackButtonDispatcher();
  }

  @override
  Widget build(BuildContext context) {
    // Claim priority, If there are parallel sub router, you will need
    // to pick which one should take priority;
    _backButtonDispatcher?.takePriority();

    return Router<void>(
      routerDelegate: _routerDelegate,
      backButtonDispatcher: _backButtonDispatcher,
    );
  }
}

class _InnerRouterDelegate extends RouterDelegate<void>
    with
        // ignore: prefer_mixin
        ChangeNotifier,
        PopNavigatorRouterDelegateMixin<void> {
  _InnerRouterDelegate(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => Navigator(
        key: navigatorKey,
        pages: [
          MaterialPage<void>(
            child: child,
          ),
        ],
        onPopPage: (route, dynamic result) => route.didPop(result),
      );

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Future<void> setNewRoutePath(dynamic configuration) async {
    // This is not required for inner router delegate because it does not
    // parse route
    assert(false);
  }
}

// Sample authentication screen
class AuthScreen extends StatelessWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Authentication'),
        ),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Login button
              OutlinedButton(
                child: const Text('Login'),
                onPressed: () {
                  Navigator.maybeOf(context)?.push<void>(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
              ),

              //
              const Divider(height: 24),

              // Register button
              OutlinedButton(
                child: const Text('Register'),
                onPressed: () {
                  Navigator.maybeOf(context)?.push<void>(
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
}

// Sample login screen
class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Login'),
        ),
        body: Center(
          child: OutlinedButton(
            child: const Text('Log In'),
            onPressed: () {
              App.signedIn.value = true;
            },
          ),
        ),
      );
}

// Sample registration screen
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Register'),
        ),
        body: Center(
          child: OutlinedButton(
            child: const Text('Register'),
            onPressed: () {
              App.signedIn.value = true;
            },
          ),
        ),
      );
}
