import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('match home route', () {
    const loc = '/';
    final routes = [
      GoRoute(pattern: '/', builder: (context, state) => DummyPage()),
    ];

    final router = _router(routes);
    final locRoutes = router.getLocRoutes(loc, routes).toList();
    expect(locRoutes.length, 1);
    expect(locRoutes[0].pattern, '/');
  });

  test('match too many routes', () {
    const loc = '/';
    final routes = [
      GoRoute(pattern: '/', builder: (context, state) => DummyPage()),
      GoRoute(pattern: '/', builder: (context, state) => DummyPage()),
    ];

    final router = _router(routes);
    expect(() => router.getLocRoutes(loc, routes), throwsException);
  });

  test('match no routes', () {
    const loc = '/';
    final routes = [
      GoRoute(pattern: '/', builder: (context, state) => DummyPage()),
    ];

    final router = _router(routes);
    final locRoutes = router.getLocRoutes(loc, routes).toList();
    expect(locRoutes.isEmpty, true);
  });

  test('match 2nd top level route', () {
    const loc = '/login';
    final routes = [
      GoRoute(pattern: '/', builder: (context, state) => DummyPage()),
      GoRoute(pattern: '/login', builder: (context, state) => DummyPage()),
    ];

    final router = _router(routes);
    final locRoutes = router.getLocRoutes(loc, routes).toList();
    expect(locRoutes.length, 1);
    expect(locRoutes[0].pattern, '/login');
  });

  test('match sub-route', () {
    final routes = [
      GoRoute(
        pattern: '/',
        builder: (context, state) => DummyPage(),
        routes: [
          GoRoute(pattern: 'login', builder: (context, state) => DummyPage())
        ],
      ),
    ];

    final router = _router(routes);
    final locRoutes = router.getLocRoutes('/login', routes).toList();
    expect(locRoutes.length, 2);
    expect(locRoutes[0].pattern, '/');
    expect(locRoutes[1].pattern, '/login');
  });
}

GoRouter _router(List<GoRoute> routes) => GoRouter(
      routes: (context, location) => routes,
      error: (context, state) => DummyPage(),
    );

class DummyPage extends Page<dynamic> {
  @override
  Route createRoute(BuildContext context) => throw UnimplementedError();
}
