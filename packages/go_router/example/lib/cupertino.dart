import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => CupertinoApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: 'Cupertino App GoRouter Example',
      );

  final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const Page1Page(),
        ),
      ),
      GoRoute(
        path: '/page2',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const Page2Page(),
        ),
      ),
    ],
    errorPageBuilder: (context, state) => CupertinoPage<void>(
      key: state.pageKey,
      child: ErrorPage(state.error),
    ),
  );
}

String _title(BuildContext context) =>
    (context as Element).findAncestorWidgetOfExactType<CupertinoApp>()!.title;

class Page1Page extends StatelessWidget {
  const Page1Page({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text(_title(context))),
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
        navigationBar: CupertinoNavigationBar(middle: Text(_title(context))),
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

class ErrorPage extends StatelessWidget {
  const ErrorPage(this.error, {Key? key}) : super(key: key);
  final Exception? error;

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
        navigationBar:
            const CupertinoNavigationBar(middle: Text('Page Not Found')),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error?.toString() ?? 'page not found'),
              CupertinoButton(
                onPressed: () => context.go('/'),
                child: const Text('Home'),
              ),
            ],
          ),
        ),
      );
}
