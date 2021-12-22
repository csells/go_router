import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ignore: implementation_imports
import 'package:go_router/src/go_route_match.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  static const title = 'GoRouter Example: Cupertino Back Button';

  @override
  Widget build(BuildContext context) => CupertinoApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: title,
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultCupertinoLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
      );

  final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: 'Page1',
        builder: (context, state) => const Page1Screen(),
        routes: [
          GoRoute(
            path: 'page2',
            name: 'Page2',
            builder: (context, state) => const Page2Screen(),
            routes: [
              GoRoute(
                path: 'page3',
                name: 'Page3',
                builder: (context, state) => const Page3Screen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class Page1Screen extends StatelessWidget {
  const Page1Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text(App.title),
        ),
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

class Page2Screen extends StatelessWidget {
  const Page2Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Page2'),
          leading: BackButton(),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoButton(
                onPressed: () => context.go('/page2/page3'),
                child: const Text('Go to page 3'),
              ),
            ],
          ),
        ),
      );
}

class Page3Screen extends StatelessWidget {
  const Page3Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Page3'),
          leading: BackButton(),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('Hold pressed on the back button to choose route')
            ],
          ),
        ),
      );
}

class BackButton extends StatelessWidget {
  const BackButton({Key? key}) : super(key: key);

  @override
  // ignore: prefer_expression_function_bodies
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onLongPress: () async {
          final router = GoRouter.of(context);
          final navigator = Navigator.of(context);
          // ignore: invalid_use_of_visible_for_testing_member
          final matches = router.routerDelegate.matches;
          if (matches.isEmpty) return;
          final match = await showMenu<GoRouteMatch?>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            context: context,
            position: const RelativeRect.fromLTRB(0, 0, 20, 20),
            items: <PopupMenuEntry<GoRouteMatch>>[
              for (final match in matches.reversed.skip(1))
                PopupMenuItem<GoRouteMatch>(
                  value: match,
                  child: Text(match.route.name ?? 'Hey'),
                ),
            ],
          );
          if (match != null) {
            // Router go does not animate views that pop
            // final location = router.routerDelegate.locationForMatch(match);
            // router.go(location);
            
            navigator.popUntil(
              (route) => route.settings.name == match.route.name,
            );
          }
        },
        child: CupertinoNavigationBarBackButton(
          onPressed: () {
            Navigator.maybePop(context);
          },
        ),
      ),
    );
  }
}
