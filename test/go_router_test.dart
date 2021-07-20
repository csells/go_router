import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('match home route', () {
    const loc = '/';
    final routes = [
      GoRoute(pattern: '/', builder: _dummy),
    ];

    final locRoutes = GoRouter.getLocRouteMatchStack(loc, routes);
    expect(locRoutes.length, 1);
    expect(locRoutes[0].route.pattern, '/');
  });

  test('match too many routes', () {
    const loc = '/';
    final routes = [
      GoRoute(pattern: '/', builder: _dummy),
      GoRoute(pattern: '/', builder: _dummy),
    ];

    try {
      GoRouter.getLocRouteMatchStack(loc, routes);
      expect(false, true);
    } on Exception catch (ex) {
      print(ex);
      expect(true, true);
    }
  });

  test('leading / on sub-route', () {
    try {
      // ignore: unused_local_variable
      final routes = [
        GoRoute(
          pattern: '/',
          builder: _dummy,
          routes: [
            GoRoute(pattern: '/foo', builder: _dummy),
          ],
        ),
      ];
      expect(false, true);
    } on Exception catch (ex) {
      print(ex);
      expect(true, true);
    }
  });

  test('trailing / on sub-route', () {
    try {
      // ignore: unused_local_variable
      final routes = [
        GoRoute(
          pattern: '/',
          builder: _dummy,
          routes: [
            GoRoute(pattern: 'foo/', builder: _dummy),
          ],
        ),
      ];
      expect(false, true);
    } on Exception catch (ex) {
      print(ex);
      expect(true, true);
    }
  });

  test('match no routes', () {
    const loc = '/foo';
    final routes = [
      GoRoute(pattern: '/', builder: _dummy),
    ];

    try {
      GoRouter.getLocRouteMatchStack(loc, routes);
      expect(false, true);
    } on Exception catch (ex) {
      print(ex);
      expect(true, true);
    }
  });

  test('match 2nd top level route', () {
    const loc = '/login';
    final routes = [
      GoRoute(pattern: '/', builder: _dummy),
      GoRoute(pattern: '/login', builder: _dummy),
    ];

    final locRoutes = GoRouter.getLocRouteMatchStack(loc, routes);
    expect(locRoutes.length, 1);
    expect(locRoutes[0].route.pattern, '/login');
  });

  test('match sub-route', () {
    final routes = [
      GoRoute(
        pattern: '/',
        builder: _dummy,
        routes: [
          GoRoute(pattern: 'login', builder: _dummy),
        ],
      ),
    ];

    final locRoutes = GoRouter.getLocRouteMatchStack('/login', routes);
    expect(locRoutes.length, 2);
    expect(locRoutes[0].route.pattern, '/');
    expect(locRoutes[1].route.pattern, 'login');
  });

  test('match sub-routes', () {
    final routes = [
      GoRoute(
        pattern: '/',
        builder: (context, state) => DummyPage(),
        routes: [
          GoRoute(
            pattern: 'family/:fid',
            builder: _dummy,
            routes: [
              GoRoute(
                pattern: 'person/:pid',
                builder: _dummy,
              ),
            ],
          ),
          GoRoute(
            pattern: 'login',
            builder: _dummy,
          ),
        ],
      ),
    ];

    final locRoutes1 = GoRouter.getLocRouteMatchStack('/', routes);
    expect(locRoutes1.length, 1);
    expect(locRoutes1[0].route.pattern, '/');

    final locRoutes2 = GoRouter.getLocRouteMatchStack('/login', routes);
    expect(locRoutes2.length, 2);
    expect(locRoutes2[0].route.pattern, '/');
    expect(locRoutes2[1].route.pattern, 'login');

    final locRoutes3 = GoRouter.getLocRouteMatchStack('/family/f2', routes);
    expect(locRoutes3.length, 2);
    expect(locRoutes3[0].route.pattern, '/');
    expect(locRoutes3[1].route.pattern, 'family/:fid');

    final locRoutes4 =
        GoRouter.getLocRouteMatchStack('/family/f2/person/p1', routes);
    expect(locRoutes4.length, 3);
    expect(locRoutes4[0].route.pattern, '/');
    expect(locRoutes4[1].route.pattern, 'family/:fid');
    expect(locRoutes4[2].route.pattern, 'person/:pid');
  });

  test('match too many sub-routes', () {
    const loc = '/foo/bar';
    final routes = [
      GoRoute(
        pattern: '/',
        builder: _dummy,
        routes: [
          GoRoute(
            pattern: 'foo/bar',
            builder: _dummy,
          ),
          GoRoute(
            pattern: 'foo',
            builder: _dummy,
            routes: [
              GoRoute(
                pattern: 'bar',
                builder: _dummy,
              ),
            ],
          ),
        ],
      ),
    ];

    try {
      GoRouter.getLocRouteMatchStack(loc, routes);
      expect(false, true);
    } on Exception catch (ex) {
      print(ex);
      expect(true, true);
    }
  });
}

// GoRouter _router(List<GoRoute> routes) => GoRouter(
//       routes: (context, location) => routes,
//       error: (context, state) => DummyPage(),
//     );

class DummyPage extends Page<dynamic> {
  @override
  Route createRoute(BuildContext context) => throw UnimplementedError();
}

Page<dynamic> _dummy(BuildContext context, GoRouterState state) => DummyPage();
