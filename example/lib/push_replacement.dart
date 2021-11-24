import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() => runApp(App());

/// sample class using simple declarative routes
class App extends StatelessWidget {
  App({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: 'GoRouter Example: Push Replacement',
      );

  late final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: const Page1PageWithPush(),
        ),
        routes: [
          GoRoute(
            name: 'page2',
            path: 'page2',
            pageBuilder: (context, state) => MaterialPage<void>(
              key: state.pageKey,
              child: Page2PageWithPushReplacement(
                int.parse(
                  state.queryParams['replace-count']!,
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

String _title(BuildContext context) 
  => (context as Element).findAncestorWidgetOfExactType<MaterialApp>()!.title;

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
                onPressed: () => context.push('/page2?replace-count=1'),
                child: const Text('Push page 2'),
              ),
            ],
          ),
        ),
      );
}

class Page2PageWithPushReplacement extends StatelessWidget {
  const Page2PageWithPushReplacement(this.pushCount, {Key? key}) : super(key: key);
  final int pushCount;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            '${_title(context)}: page 2 \n w/ replace count ${pushCount - 1}',
            textAlign: TextAlign.center,
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('This Page was replaced ${pushCount - 1} times'),
              if (kIsWeb) const Text('(pay attention to the URL) \n'),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  onPressed: () => context.pushReplacementNamed(
                    'page2',
                    queryParams: {'replace-count': (pushCount + 1).toString()},
                  ),
                  child: const Text(
                    'Replace page 2 with another page 2',
                  ),
                ),
              ),
              const Text(
                '\nUnlike pushing pages, if you click the back button of '
                'the AppBar, \n you will return home directly',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}
