import 'package:adaptive_navigation/adaptive_navigation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  static const title = 'GoRouter Example: Shared Scaffold';

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: title,
      );

  final _router = GoRouter(
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Page1View(),
      ),
      GoRoute(
        path: '/page2',
        builder: (context, state) => const Page2View(),
      ),
    ],
    navigatorBuilder: (context, state, child) => SharedScaffold(
      selectedIndex: state.subloc == '/' ? 0 : 1,
      body: child,
    ),
  );
}

class SharedScaffold extends StatelessWidget {
  const SharedScaffold({
    required this.selectedIndex,
    required this.body,
    Key? key,
  }) : super(key: key);

  final int selectedIndex;
  final Widget body;

  @override
  Widget build(BuildContext context) => AdaptiveNavigationScaffold(
        selectedIndex: selectedIndex,
        destinations: const [
          AdaptiveScaffoldDestination(title: 'Page 1', icon: Icons.first_page),
          AdaptiveScaffoldDestination(title: 'Page 2', icon: Icons.last_page),
        ],
        appBar: AdaptiveAppBar(title: const Text(App.title)),
        onDestinationSelected: (value) {
          switch (value) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/page2');
              break;
            default:
              throw Exception('Invalid index');
          }
        },
        navigationTypeResolver: (context) =>
            MediaQuery.of(context).size.width < 600
                ? NavigationType.bottom
                : NavigationType.drawer,
        body: body,
      );
}

class Page1View extends StatelessWidget {
  const Page1View({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => context.go('/page2'),
              child: const Text('Go to page 2'),
            ),
          ],
        ),
      );
}

class Page2View extends StatelessWidget {
  const Page2View({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go to home page'),
            ),
          ],
        ),
      );
}
