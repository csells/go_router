import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shared/pages.dart';

void main() => runApp(App());

/// sample class using simple declarative routes
class App extends StatelessWidget {
  App({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: 'GoRouter Example: Push',
      );

  late final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: const Page1PageWithPush(),
        ),
      ),
      GoRoute(
        name: 'page2',
        path: '/page2',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: Page2PageWithPush(int.parse(state.queryParams['push-count']!)),
        ),
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      child: ErrorPage(state.error),
    ),
  );
}

String _title(BuildContext context) =>
    (context as Element).findAncestorWidgetOfExactType<MaterialApp>()!.title;

class Page1PageWithPush extends StatelessWidget {
  const Page1PageWithPush({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('${_title(context)}: page 1')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => context.push('/page2?push-count=1'),
                child: const Text('Push page 2'),
              ),
            ],
          ),
        ),
      );
}

class Page2PageWithPush extends StatelessWidget {
  const Page2PageWithPush(this.pushCount, {Key? key}) : super(key: key);
  final int pushCount;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('${_title(context)}: page 2 w/ push count $pushCount'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Go to home page'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  onPressed: () => context.pushNamed(
                    'page2',
                    queryParams: {'push-count': (pushCount + 1).toString()},
                  ),
                  child: const Text('Push page 2 (again)'),
                ),
              ),
            ],
          ),
        ),
      );
}
