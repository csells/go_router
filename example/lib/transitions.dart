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
        title: 'Custom Transitions GoRouter Example',
      );

  final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        redirect: (_) => '/fade',
      ),
      GoRoute(
        path: '/fade',
        builder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const TransitionsPage(kind: 'fade', color: Colors.red),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/scale',
        builder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const TransitionsPage(kind: 'scale', color: Colors.green),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              ScaleTransition(scale: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/slide',
        builder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const TransitionsPage(kind: 'slide', color: Colors.yellow),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
                  position: animation.drive(
                    Tween<Offset>(
                      begin: const Offset(0.25, 0.25),
                      end: Offset.zero,
                    ).chain(CurveTween(curve: Curves.easeIn)),
                  ),
                  child: child),
        ),
      ),
      GoRoute(
        path: '/rotation',
        builder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const TransitionsPage(kind: 'rotation', color: Colors.purple),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              RotationTransition(turns: animation, child: child),
        ),
      ),
    ],
    error: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      child: ErrorPage(state.error),
    ),
  );
}

class TransitionsPage extends StatelessWidget {
  static final kinds = ['fade', 'scale', 'slide', 'rotation'];
  final Color color;
  final String kind;
  const TransitionsPage({required this.color, required this.kind, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('${_title(context)}: $kind')),
        body: Container(
          color: color,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final kind in kinds)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: ElevatedButton(
                      onPressed: () => context.go('/$kind'),
                      child: Text('$kind transition'),
                    ),
                  )
              ],
            ),
          ),
        ),
      );

  static String _title(BuildContext context) =>
      (context as Element).findAncestorWidgetOfExactType<MaterialApp>()!.title;
}
