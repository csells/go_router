import 'package:flutter/src/foundation/diagnostics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  final context = DummyBuildContext();

  test('match home route', () {
    const loc = '/';
    final routes = [
      GoRoute(path: '/', builder: (builder, state) => HomePage()),
    ];

    final router = _router(routes);
    final locPages = router.getLocPages(context, loc, routes);
    final entries = locPages.entries.toList();
    expect(entries.length, 1);
    expect(entries[0].key, '/');
    expect(entries[0].value.runtimeType, HomePage);
  });

  test('match too many routes', () {
    const loc = '/';
    final routes = [
      GoRoute(path: '/', builder: _dummy),
      GoRoute(path: '/', builder: _dummy),
    ];

    try {
      final router = _router(routes);
      router.getLocPages(context, loc, routes);
      expect(false, true);
    } on Exception catch (ex) {
      dump(ex);
      expect(true, true);
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
      expect(true, true);
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
      expect(true, true);
    }
  });

  test('lack of leading / on top level route', () {
    try {
      // ignore: unused_local_variable
      final routes = [
        GoRoute(path: 'foo', builder: _dummy),
      ];
      final router = _router(routes);
      router.getLocPages(context, 'foo', routes);
      expect(false, true);
    } on Exception catch (ex) {
      dump(ex);
      expect(true, true);
    }
  });

  test('match no routes', () {
    const loc = '/foo';
    final routes = [
      GoRoute(path: '/', builder: _dummy),
    ];

    try {
      final router = _router(routes);
      router.getLocPages(context, loc, routes);
      expect(false, true);
    } on Exception catch (ex) {
      dump(ex);
      expect(true, true);
    }
  });

  test('match 2nd top level route', () {
    const loc = '/login';
    final routes = [
      GoRoute(path: '/', builder: (builder, state) => HomePage()),
      GoRoute(path: '/login', builder: (builder, state) => LoginPage()),
    ];

    final router = _router(routes);
    final locPages = router.getLocPages(context, loc, routes);
    final entries = locPages.entries.toList();
    expect(entries.length, 1);
    expect(entries[0].key, '/login');
    expect(entries[0].value.runtimeType, LoginPage);
  });

  test('match sub-route', () {
    const loc = '/login';
    final routes = [
      GoRoute(
        path: '/',
        builder: (builder, state) => HomePage(),
        routes: [
          GoRoute(path: 'login', builder: (builder, state) => LoginPage()),
        ],
      ),
    ];

    final router = _router(routes);
    final locPages = router.getLocPages(context, loc, routes);
    final entries = locPages.entries.toList();
    expect(entries.length, 2);
    expect(entries[0].key, '/');
    expect(entries[0].value.runtimeType, HomePage);
    expect(entries[1].key, '/login');
    expect(entries[1].value.runtimeType, LoginPage);
  });

  test('match sub-routes', () {
    final routes = [
      GoRoute(
        path: '/',
        builder: (context, state) => HomePage(),
        routes: [
          GoRoute(
            path: 'family/:fid',
            builder: (context, state) => FamilyPage(
              state.params['fid']!,
            ),
            routes: [
              GoRoute(
                path: 'person/:pid',
                builder: (context, state) => PersonPage(
                  state.params['fid']!,
                  state.params['pid']!,
                ),
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
      final locPages = router.getLocPages(context, '/', routes);
      final entries = locPages.entries.toList();
      expect(entries.length, 1);
      expect(entries[0].key, '/');
      expect(entries[0].value.runtimeType, HomePage);
    }
    {
      final locPages = router.getLocPages(context, '/login', routes);
      final entries = locPages.entries.toList();
      expect(entries.length, 2);
      expect(entries[0].key, '/');
      expect(entries[0].value.runtimeType, HomePage);
      expect(entries[1].key, '/login');
      expect(entries[1].value.runtimeType, LoginPage);
    }
    {
      final locPages = router.getLocPages(context, '/family/f2', routes);
      final entries = locPages.entries.toList();
      expect(entries.length, 2);
      expect(entries[0].key, '/');
      expect(entries[0].value.runtimeType, HomePage);
      expect(entries[1].key, '/family/f2');
      expect(entries[1].value.runtimeType, FamilyPage);
      expect((entries[1].value as FamilyPage).fid, 'f2');
    }
    {
      final locPages =
          router.getLocPages(context, '/family/f2/person/p1', routes);
      final entries = locPages.entries.toList();
      expect(entries.length, 3);
      expect(entries[0].key, '/');
      expect(entries[0].value.runtimeType, HomePage);
      expect(entries[1].key, '/family/f2');
      expect(entries[1].value.runtimeType, FamilyPage);
      expect((entries[1].value as FamilyPage).fid, 'f2');
      expect(entries[2].key, '/family/f2/person/p1');
      expect(entries[2].value.runtimeType, PersonPage);
      expect((entries[2].value as PersonPage).fid, 'f2');
      expect((entries[2].value as PersonPage).pid, 'p1');
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
      router.getLocPages(context, loc, routes);
      expect(false, true);
    } on Exception catch (ex) {
      dump(ex);
      expect(true, true);
    }
  });

  test('redirect', () {
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
      routes: (context, location) => routes,
      error: _dummy,
      guard: LoginGuard(),
    );
    expect(router.routerDelegate.currentConfiguration.toString(), '/');

    router.go('/dummy');
    expect(router.routerDelegate.currentConfiguration.toString(), '/login');
  });

  test('initial location', () {
    final routes = [
      GoRoute(
        path: '/',
        builder: (builder, state) => HomePage(),
        routes: [
          GoRoute(path: 'dummy', builder: (builder, state) => DummyPage()),
        ],
      ),
    ];

    final router = GoRouter(
      routes: (context, location) => routes,
      error: _dummy,
      initialLocation: '/dummy',
    );
    expect(router.routerDelegate.currentConfiguration.toString(), '/dummy');
  });

  test('duplicate path param', () {
    // TODO
  });

  test('duplicate query param', () {
    // TODO
  });

  test('duplicate path + query param', () {
    // TODO
  });
}

GoRouter _router(List<GoRoute> routes) => GoRouter(
      routes: (context, location) => routes,
      error: _dummy,
    );

class HomePage extends DummyPage {}

class LoginPage extends DummyPage {}

class FamilyPage extends DummyPage {
  final String fid;
  FamilyPage(this.fid);
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

// ignore: avoid_print
void dump(Object o) => print(o);

class LoginGuard extends GoRouterGuard {
  @override
  String? redirect(String location) => location == '/login' ? null : '/login';
}

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
