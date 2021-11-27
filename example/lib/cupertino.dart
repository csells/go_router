import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  static const title = 'GoRouter Example: Cupertino App';

  @override
  Widget build(BuildContext context) => CupertinoApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: title,
      );

  final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Page1Page(),
      ),
      GoRoute(
        path: '/page2',
        builder: (context, state) => const Page2Page(),
      ),
    ],
  );
}

class Page1Page extends StatelessWidget {
  const Page1Page({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text(App.title)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoButton(
                onPressed: () => context.go('/page2'),
                child: const Text('Go to page 2'),
              ),
            ],
          ),
        ),
      );
}

class Page2Page extends StatelessWidget {
  const Page2Page({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text(App.title)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoButton(
                onPressed: () => context.go('/'),
                child: const Text('Go to home page'),
              ),
            ],
          ),
        ),
      );
}
