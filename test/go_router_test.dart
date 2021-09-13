import 'package:flutter/src/foundation/diagnostics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router/src/go_router_impl.dart';

void main() {
  group('path routes', () {
    test('match home route', () {
      const loc = '/';
      final routes = [
        GoRoute(path: '/', builder: (builder, state) => HomePage()),
      ];

      final router = _router(routes);
      final matches = router.routerDelegate.getLocRouteMatches(loc);
      expect(matches.length, 1);
      expect(matches[0].fullpath, '/');
      expect(router.pageFor(matches[0]).runtimeType, HomePage);
    });

    test('match too many routes', () {
      const loc = '/';
      final routes = [
        GoRoute(path: '/', builder: _dummy),
        GoRoute(path: '/', builder: _dummy),
      ];

      try {
        final router = _router(routes);
        router.routerDelegate.getLocRouteMatches(loc);
        expect(false, true);
      } on Exception catch (ex) {
        dump(ex);
      }
    });

    test('empty path', () {
      try {
        GoRoute(path: '');
        expect(false, true);
      } on Exception catch (ex) {
        dump(ex);
      }
    });

    test('leading / on sub-route', () {
      try {
        // ignore: unused_local_variable
        final routes = [
          GoRoute(
            path: '/',
            builder: _dummy,
            routes: [
              GoRoute(
                path: '/foo',
                builder: _dummy,
              ),
            ],
          ),
        ];
        expect(false, true);
      } on Exception catch (ex) {
        dump(ex);
      }
    });

    test('trailing / on sub-route', () {
      try {
        // ignore: unused_local_variable
        final routes = [
          GoRoute(
            path: '/',
            builder: _dummy,
            routes: [
              GoRoute(
                path: 'foo/',
                builder: _dummy,
              ),
            ],
          ),
        ];
        expect(false, true);
      } on Exception catch (ex) {
        dump(ex);
      }
    });

    test('lack of leading / on top-level route', () {
      try {
        final routes = [
          GoRoute(path: 'foo', builder: _dummy),
        ];
        _router(routes);
        expect(false, true);
      } on Exception catch (ex) {
        dump(ex);
      }
    });

    test('match no routes', () {
      const loc = '/foo';
      final routes = [
        GoRoute(path: '/', builder: _dummy),
      ];

      try {
        final router = _router(routes);
        router.routerDelegate.getLocRouteMatches(loc);
        expect(false, true);
      } on Exception catch (ex) {
        dump(ex);
      }
    });

    test('match 2nd top level route', () {
      const loc = '/login';
      final routes = [
        GoRoute(path: '/', builder: (builder, state) => HomePage()),
        GoRoute(path: '/login', builder: (builder, state) => LoginPage()),
      ];

      final router = _router(routes);
      final matches = router.routerDelegate.getLocRouteMatches(loc);
      expect(matches.length, 1);
      expect(matches[0].subloc, '/login');
      expect(router.pageFor(matches[0]).runtimeType, LoginPage);
    });

    test('match sub-route', () {
      const loc = '/login';
      final routes = [
        GoRoute(
          path: '/',
          builder: (builder, state) => HomePage(),
          routes: [
            GoRoute(
              path: 'login',
              builder: (builder, state) => LoginPage(),
            ),
          ],
        ),
      ];

      final router = _router(routes);
      final matches = router.routerDelegate.getLocRouteMatches(loc);
      expect(matches.length, 2);
      expect(matches[0].subloc, '/');
      expect(router.pageFor(matches[0]).runtimeType, HomePage);
      expect(matches[1].subloc, '/login');
      expect(router.pageFor(matches[1]).runtimeType, LoginPage);
    });

    test('match sub-routes', () {
      final routes = [
        GoRoute(
          path: '/',
          builder: (context, state) => HomePage(),
          routes: [
            GoRoute(
              path: 'family/:fid',
              builder: (context, state) => FamilyPage('dummy'),
              routes: [
                GoRoute(
                  path: 'person/:pid',
                  builder: (context, state) => PersonPage('dummy', 'dummy'),
                ),
              ],
            ),
            GoRoute(
              path: 'login',
              builder: (context, state) => LoginPage(),
            ),
          ],
        ),
      ];

      final router = _router(routes);
      {
        final matches = router.routerDelegate.getLocRouteMatches('/');
        expect(matches.length, 1);
        expect(matches[0].fullpath, '/');
        expect(router.pageFor(matches[0]).runtimeType, HomePage);
      }
      {
        final matches = router.routerDelegate.getLocRouteMatches('/login');
        expect(matches.length, 2);
        expect(matches[0].subloc, '/');
        expect(router.pageFor(matches[0]).runtimeType, HomePage);
        expect(matches[1].subloc, '/login');
        expect(router.pageFor(matches[1]).runtimeType, LoginPage);
      }
      {
        final matches = router.routerDelegate.getLocRouteMatches('/family/f2');
        expect(matches.length, 2);
        expect(matches[0].subloc, '/');
        expect(router.pageFor(matches[0]).runtimeType, HomePage);
        expect(matches[1].subloc, '/family/f2');
        expect(router.pageFor(matches[1]).runtimeType, FamilyPage);
      }
      {
        final matches =
            router.routerDelegate.getLocRouteMatches('/family/f2/person/p1');
        expect(matches.length, 3);
        expect(matches[0].subloc, '/');
        expect(router.pageFor(matches[0]).runtimeType, HomePage);
        expect(matches[1].subloc, '/family/f2');
        expect(router.pageFor(matches[1]).runtimeType, FamilyPage);
        expect(matches[2].subloc, '/family/f2/person/p1');
        expect(router.pageFor(matches[2]).runtimeType, PersonPage);
      }
    });

    test('match too many sub-routes', () {
      const loc = '/foo/bar';
      final routes = [
        GoRoute(
          path: '/',
          builder: _dummy,
          routes: [
            GoRoute(
              path: 'foo/bar',
              builder: _dummy,
            ),
            GoRoute(
              path: 'foo',
              builder: _dummy,
              routes: [
                GoRoute(
                  path: 'bar',
                  builder: _dummy,
                ),
              ],
            ),
          ],
        ),
      ];

      try {
        final router = _router(routes);
        router.routerDelegate.getLocRouteMatches(loc);
        expect(false, true);
      } on Exception catch (ex) {
        dump(ex);
      }
    });

    test('router state', () {
      final routes = [
        GoRoute(
          path: '/',
          builder: (builder, state) {
            expect(
              state.location,
              anyOf(['/', '/login', '/family/f2', '/family/f2/person/p1']),
            );
            expect(state.subloc, '/');
            expect(state.path, '/');
            expect(state.fullpath, '/');
            expect(state.params, <String, String>{});
            expect(state.error, null);
            return HomePage();
          },
          routes: [
            GoRoute(
              path: 'login',
              builder: (builder, state) {
                expect(state.location, '/login');
                expect(state.subloc, '/login');
                expect(state.path, 'login');
                expect(state.fullpath, '/login');
                expect(state.params, <String, String>{});
                expect(state.error, null);
                return LoginPage();
              },
            ),
            GoRoute(
              path: 'family/:fid',
              builder: (builder, state) {
                expect(
                  state.location,
                  anyOf(['/family/f2', '/family/f2/person/p1']),
                );
                expect(state.subloc, '/family/f2');
                expect(state.path, 'family/:fid');
                expect(state.fullpath, '/family/:fid');
                expect(state.params, <String, String>{'fid': 'f2'});
                expect(state.error, null);
                return FamilyPage(state.params['fid']!);
              },
              routes: [
                GoRoute(
                  path: 'person/:pid',
                  builder: (context, state) {
                    expect(state.location, '/family/f2/person/p1');
                    expect(state.subloc, '/family/f2/person/p1');
                    expect(state.path, 'person/:pid');
                    expect(state.fullpath, '/family/:fid/person/:pid');
                    expect(
                      state.params,
                      <String, String>{'fid': 'f2', 'pid': 'p1'},
                    );
                    expect(state.error, null);
                    return PersonPage(
                        state.params['fid']!, state.params['pid']!);
                  },
                ),
              ],
            ),
          ],
        ),
      ];

      final router = _router(routes);
      router.go('/');
      router.go('/login');
      router.go('/family/f2');
      router.go('/family/f2/person/p1');
    });

    test('listen to the router', () {
      final routes = [GoRoute(path: '/', builder: _dummy)];
      final router = _router(routes);

      var count = 0;
      void counter() => ++count;
      router.addListener(counter);
      router.go('/');
      expect(count, 1);
      router.removeListener(counter);
      router.go('/');
      expect(count, 1);
    });
  });

  group('named routes', () {
    test('match home route', () {
      final routes = [
        GoRoute(
            name: 'home', path: '/', builder: (builder, state) => HomePage()),
      ];

      final router = _router(routes);
      final match = router.routerDelegate.getNameRouteMatch('home');

      expect(match, isNotNull);
      expect(match!.fullpath, '/');
      expect(router.pageFor(match).runtimeType, HomePage);

      router.goName('home');
    });

    test('match too many routes', () {
      final routes = [
        GoRoute(name: 'home', path: '/', builder: _dummy),
        GoRoute(name: 'home', path: '/', builder: _dummy),
      ];

      try {
        _router(routes);
        expect(false, true);
      } on Exception catch (ex) {
        dump(ex);
      }
    });

    test('empty name', () {
      try {
        GoRoute(name: '', path: '/');
        expect(false, true);
      } on Exception catch (ex) {
        dump(ex);
      }
    });

    test('match no routes', () {
      final routes = [
        GoRoute(name: 'home', path: '/', builder: _dummy),
      ];

      try {
        final router = _router(routes);
        router.goName('work');
        expect(false, true);
      } on Exception catch (ex) {
        dump(ex);
      }
    });

    test('match 2nd top level route', () {
      final routes = [
        GoRoute(
          name: 'home',
          path: '/',
          builder: (builder, state) => HomePage(),
        ),
        GoRoute(
          name: 'login',
          path: '/login',
          builder: (builder, state) => LoginPage(),
        ),
      ];

      final router = _router(routes);
      final match = router.routerDelegate.getNameRouteMatch('login');
      expect(match, isNotNull);
      expect(match!.subloc, '/login');
      expect(router.pageFor(match).runtimeType, LoginPage);
    });

    test('match sub-route', () {
      final routes = [
        GoRoute(
          name: 'home',
          path: '/',
          builder: (builder, state) => HomePage(),
          routes: [
            GoRoute(
              name: 'login',
              path: 'login',
              builder: (builder, state) => LoginPage(),
            ),
          ],
        ),
      ];

      final router = _router(routes);
      final match = router.routerDelegate.getNameRouteMatch('login');
      expect(match, isNotNull);
      expect(match!.subloc, '/login');
      expect(router.pageFor(match).runtimeType, LoginPage);
    });

    test('too few parameters', () {
      final routes = [
        GoRoute(
          path: '/',
          builder: (context, state) => HomePage(),
          routes: [
            GoRoute(
              path: 'family/:fid',
              builder: (context, state) => FamilyPage('dummy'),
              routes: [
                GoRoute(
                  path: 'person/:pid',
                  builder: (context, state) => PersonPage('dummy', 'dummy'),
                ),
              ],
            ),
          ],
        ),
      ];

      final router = _router(routes);
      try {
        router.routerDelegate.getNameRouteMatch('person', {'fid': 'f2'});
        expect(false, true);
      } on Exception catch (ex) {
        dump(ex);
      }
    });

    test('extra params as query params', () {
      final routes = [
        GoRoute(
          name: 'home',
          path: '/',
          builder: (builder, state) => HomePage(),
        ),
        GoRoute(
          name: 'login',
          path: '/login',
          builder: (builder, state) {
            expect(state.location, '/login?from=/');
            expect(state.params, {'from': '/'});
            return LoginPage();
          },
        ),
      ];

      final router = _router(routes);
      router.goName('login', {'from': '/'});
      router.routerDelegate.build(DummyBuildContext());
    });
  });

  group('redirects', () {
    test('top-level redirect', () {
      final routes = [
        GoRoute(
          path: '/',
          builder: (builder, state) => HomePage(),
          routes: [
            GoRoute(path: 'dummy', builder: (builder, state) => DummyPage()),
            GoRoute(path: 'login', builder: (builder, state) => LoginPage()),
          ],
        ),
      ];

      final router = GoRouter(
        routes: routes,
        error: _dummy,
        redirect: (state) => state.subloc == '/login' ? null : '/login',
      );
      expect(router.location, '/login');
    });

    test('route-level redirect', () {
      final routes = [
        GoRoute(
          path: '/',
          builder: (builder, state) => HomePage(),
          routes: [
            GoRoute(
              path: 'dummy',
              builder: (builder, state) => DummyPage(),
              redirect: (state) => '/login',
            ),
            GoRoute(
              path: 'login',
              builder: (builder, state) => LoginPage(),
            ),
          ],
        ),
      ];

      final router = GoRouter(
        routes: routes,
        error: _dummy,
      );
      router.go('/dummy');
      expect(router.location, '/login');
    });

    test('multiple mixed redirect', () {
      final routes = [
        GoRoute(
          path: '/',
          builder: (builder, state) => HomePage(),
          routes: [
            GoRoute(
              path: 'dummy1',
              builder: (builder, state) => DummyPage(),
            ),
            GoRoute(
              path: 'dummy2',
              builder: (builder, state) => DummyPage(),
              redirect: (state) => '/',
            ),
          ],
        ),
      ];

      final router = GoRouter(
        routes: routes,
        error: _dummy,
        redirect: (state) => state.subloc == '/dummy1' ? '/dummy2' : null,
      );
      router.go('/dummy1');
      expect(router.location, '/');
    });

    test('top-level redirect loop', () {
      final router = GoRouter(
        routes: [],
        error: (context, state) => ErrorPage(state.error!),
        redirect: (state) => state.subloc == '/'
            ? '/login'
            : state.subloc == '/login'
                ? '/'
                : null,
      );

      final matches = router.routerDelegate.matches;
      expect(matches.length, 1);
      expect(router.pageFor(matches[0]).runtimeType, ErrorPage);
      expect((router.pageFor(matches[0]) as ErrorPage).ex, isNotNull);
      dump((router.pageFor(matches[0]) as ErrorPage).ex);
    });

    test('route-level redirect loop', () {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            redirect: (state) => '/login',
          ),
          GoRoute(
            path: '/login',
            redirect: (state) => '/',
          ),
        ],
        error: (context, state) => ErrorPage(state.error!),
      );

      final matches = router.routerDelegate.matches;
      expect(matches.length, 1);
      expect(router.pageFor(matches[0]).runtimeType, ErrorPage);
      expect((router.pageFor(matches[0]) as ErrorPage).ex, isNotNull);
      dump((router.pageFor(matches[0]) as ErrorPage).ex);
    });

    test('mixed redirect loop', () {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/login',
            redirect: (state) => '/',
          ),
        ],
        error: (context, state) => ErrorPage(state.error!),
        redirect: (state) => state.subloc == '/' ? '/login' : null,
      );

      final matches = router.routerDelegate.matches;
      expect(matches.length, 1);
      expect(router.pageFor(matches[0]).runtimeType, ErrorPage);
      expect((router.pageFor(matches[0]) as ErrorPage).ex, isNotNull);
      dump((router.pageFor(matches[0]) as ErrorPage).ex);
    });

    test('top-level redirect loop w/ query params', () {
      final router = GoRouter(
        routes: [],
        error: (context, state) => ErrorPage(state.error!),
        redirect: (state) => state.subloc == '/'
            ? '/login?from=${state.location}'
            : state.subloc == '/login'
                ? '/'
                : null,
      );

      final matches = router.routerDelegate.matches;
      expect(matches.length, 1);
      expect(router.pageFor(matches[0]).runtimeType, ErrorPage);
      expect((router.pageFor(matches[0]) as ErrorPage).ex, isNotNull);
      dump((router.pageFor(matches[0]) as ErrorPage).ex);
    });

    test('expect null path/fullpath on top-level redirect', () {
      final routes = [
        GoRoute(
          path: '/',
          builder: (builder, state) => HomePage(),
        ),
        GoRoute(
          path: '/dummy',
          redirect: (state) => '/',
        ),
      ];

      final router = GoRouter(
        routes: routes,
        error: _dummy,
        initialLocation: '/dummy',
      );
      expect(router.location, '/');
    });

    test('top-level redirect state', () {
      final routes = [
        GoRoute(
          path: '/',
          builder: (builder, state) => HomePage(),
        ),
        GoRoute(
          path: '/login',
          builder: (builder, state) => LoginPage(),
        ),
      ];

      GoRouter(
        routes: routes,
        error: _dummy,
        initialLocation: '/login?from=/',
        debugLogDiagnostics: true,
        redirect: (state) {
          expect(Uri.parse(state.location).queryParameters, isNotEmpty);
          expect(Uri.parse(state.subloc).queryParameters, isEmpty);
          expect(state.path, isNull);
          expect(state.fullpath, isNull);
          return null;
        },
      );
    });

    test('route-level redirect state', () {
      const loc = '/book/0';
      final routes = [
        GoRoute(
          path: '/book/:bookId',
          redirect: (state) {
            expect(state.location, loc);
            expect(state.subloc, loc);
            expect(state.path, '/book/:bookId');
            expect(state.fullpath, '/book/:bookId');
            expect(state.params, {'bookId': '0'});
            return '/book/${state.params['bookId']!}';
          },
        ),
        GoRoute(
          path: '/book/:bookId',
          builder: (builder, state) {
            expect(state.params, {'bookId': '0'});
            return DummyPage();
          },
        ),
      ];

      GoRouter(
        routes: routes,
        error: _dummy,
        initialLocation: loc,
        debugLogDiagnostics: true,
      );
    });
  });

  group('initial locaton', () {
    test('initial location', () {
      final routes = [
        GoRoute(
          path: '/',
          builder: (builder, state) => HomePage(),
          routes: [
            GoRoute(
              path: 'dummy',
              builder: (builder, state) => DummyPage(),
            ),
          ],
        ),
      ];

      final router = GoRouter(
        routes: routes,
        error: _dummy,
        initialLocation: '/dummy',
      );
      expect(router.location, '/dummy');
    });

    test('initial location w/ redirection', () {
      final routes = [
        GoRoute(
          path: '/',
          builder: (builder, state) => HomePage(),
        ),
        GoRoute(
          path: '/dummy',
          redirect: (state) => '/',
        ),
      ];

      final router = GoRouter(
        routes: routes,
        error: _dummy,
        initialLocation: '/dummy',
      );
      expect(router.location, '/');
    });
  });

  group('params', () {
    test('duplicate path param', () {
      try {
        GoRouter(
          routes: [
            GoRoute(
              path: '/:id/:blah/:bam/:id/:blah',
              builder: _dummy,
            ),
          ],
          error: (context, state) => ErrorPage(state.error!),
          initialLocation: '/0/1/2/0/1',
        );
        expect(false, true);
      } on Exception catch (ex) {
        dump(ex);
      }
    });

    test('duplicate query param', () {
      GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_dummy, state) {
              expect(state.params, {'id': '0'});
              return DummyPage();
            },
          ),
        ],
        error: _dummy,
        initialLocation: '/?id=0&id=1',
      );
    });

    test('duplicate path + query param', () {
      GoRouter(
        routes: [
          GoRoute(
            path: '/:id',
            builder: (_dummy, state) {
              expect(state.params, {'id': '0'});
              return DummyPage();
            },
          ),
        ],
        error: _dummy,
        initialLocation: '/0?id=1',
      );
    });
  });
}

GoRouter _router(List<GoRoute> routes) => GoRouter(
      routes: routes,
      error: _dummy,
      debugLogDiagnostics: true,
    );

class ErrorPage extends DummyPage {
  final Exception ex;
  ErrorPage(this.ex);
}

class HomePage extends DummyPage {}

class LoginPage extends DummyPage {}

class FamilyPage extends DummyPage {
  final String fid;
  FamilyPage(this.fid);
}

class FamiliesPage extends DummyPage {
  final String selectedFid;
  FamiliesPage({required this.selectedFid});
}

class PersonPage extends DummyPage {
  final String fid;
  final String pid;
  PersonPage(this.fid, this.pid);
}

class DummyPage extends Page<dynamic> {
  @override
  Route createRoute(BuildContext context) => throw UnimplementedError();
}

Page<dynamic> _dummy(BuildContext context, GoRouterState state) => DummyPage();

extension on GoRouter {
  Page<dynamic> pageFor(GoRouteMatch match) => match.route.builder(
        DummyBuildContext(),
        GoRouterState(location: 'DO NOT TEST', subloc: match.subloc),
      );
}

// ignore: avoid_print
void dump(Object o) => print(o);

class DummyBuildContext implements BuildContext {
  @override
  bool get debugDoingBuild => throw UnimplementedError();

  @override
  InheritedWidget dependOnInheritedElement(InheritedElement ancestor,
      {Object aspect = 1}) {
    throw UnimplementedError();
  }

  @override
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>(
      {Object? aspect}) {
    throw UnimplementedError();
  }

  @override
  DiagnosticsNode describeElement(String name,
      {DiagnosticsTreeStyle style = DiagnosticsTreeStyle.errorProperty}) {
    throw UnimplementedError();
  }

  @override
  List<DiagnosticsNode> describeMissingAncestor(
      {required Type expectedAncestorType}) {
    throw UnimplementedError();
  }

  @override
  DiagnosticsNode describeOwnershipChain(String name) {
    throw UnimplementedError();
  }

  @override
  DiagnosticsNode describeWidget(String name,
      {DiagnosticsTreeStyle style = DiagnosticsTreeStyle.errorProperty}) {
    throw UnimplementedError();
  }

  @override
  T? findAncestorRenderObjectOfType<T extends RenderObject>() {
    throw UnimplementedError();
  }

  @override
  T? findAncestorStateOfType<T extends State<StatefulWidget>>() {
    throw UnimplementedError();
  }

  @override
  T? findAncestorWidgetOfExactType<T extends Widget>() {
    throw UnimplementedError();
  }

  @override
  RenderObject? findRenderObject() {
    throw UnimplementedError();
  }

  @override
  T? findRootAncestorStateOfType<T extends State<StatefulWidget>>() {
    throw UnimplementedError();
  }

  @override
  InheritedElement?
      getElementForInheritedWidgetOfExactType<T extends InheritedWidget>() {
    throw UnimplementedError();
  }

  @override
  BuildOwner? get owner => throw UnimplementedError();

  @override
  Size? get size => throw UnimplementedError();

  @override
  void visitAncestorElements(bool Function(Element element) visitor) {}

  @override
  void visitChildElements(ElementVisitor visitor) {}

  @override
  Widget get widget => throw UnimplementedError();
}
