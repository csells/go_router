import 'package:flutter/src/foundation/diagnostics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  final context = DummyBuildContext();

  test('match home route', () {
    const loc = '/';
    final routes = [
      GoRoute(pattern: '/', builder: (builder, state) => HomePage()),
    ];

    final router = _router(routes);
    final locPages = router.getLocPages(context, loc, routes);
    expect(locPages.length, 1);
    expect(locPages.entries.toList()[0].key, '/');
    expect(locPages.entries.toList()[0].value.runtimeType, HomePage);
  });

  test('match too many routes', () {
    const loc = '/';
    final routes = [
      GoRoute(pattern: '/', builder: _dummy),
      GoRoute(pattern: '/', builder: _dummy),
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
          pattern: '/',
          builder: _dummy,
          routes: [
            GoRoute(
              pattern: '/foo',
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
          pattern: '/',
          builder: _dummy,
          routes: [
            GoRoute(
              pattern: 'foo/',
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

  test('match no routes', () {
    const loc = '/foo';
    final routes = [
      GoRoute(pattern: '/', builder: _dummy),
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
      GoRoute(pattern: '/', builder: (builder, state) => HomePage()),
      GoRoute(pattern: '/login', builder: (builder, state) => LoginPage()),
    ];

    final router = _router(routes);
    final locPages = router.getLocPages(context, loc, routes);
    expect(locPages.length, 1);
    expect(locPages.entries.toList()[0].key, '/login');
    expect(locPages.entries.toList()[0].value.runtimeType, LoginPage);
  });

  test('match sub-route', () {
    const loc = '/login';
    final routes = [
      GoRoute(
        pattern: '/',
        builder: (builder, state) => HomePage(),
        routes: [
          GoRoute(pattern: 'login', builder: (builder, state) => LoginPage()),
        ],
      ),
    ];

    final router = _router(routes);
    final locPages = router.getLocPages(context, loc, routes);
    expect(locPages.length, 2);
    expect(locPages.entries.toList()[0].key, '/');
    expect(locPages.entries.toList()[0].value.runtimeType, HomePage);
    expect(locPages.entries.toList()[1].key, '/login');
    expect(locPages.entries.toList()[1].value.runtimeType, LoginPage);
  });

  // test('match sub-routes', () {
  //   final routes = [
  //     GoRoute(
  //       pattern: '/',
  //       builder: (context, state) => DummyPage(),
  //       routes: [
  //         GoRoute(
  //           pattern: 'family/:fid',
  //           builder: _dummy,
  //           routes: [
  //             GoRoute(
  //               pattern: 'person/:pid',
  //               builder: _dummy,
  //             ),
  //           ],
  //         ),
  //         GoRoute(
  //           pattern: 'login',
  //           builder: _dummy,
  //         ),
  //       ],
  //     ),
  //   ];

  //   final locRoutes1 = GoRouter._getLocRouteMatchStack('/', routes);
  //   expect(locRoutes1.length, 1);
  //   expect(locRoutes1[0].route.pattern, '/');

  //   final locRoutes2 = GoRouter._getLocRouteMatchStack('/login', routes);
  //   expect(locRoutes2.length, 2);
  //   expect(locRoutes2[0].route.pattern, '/');
  //   expect(locRoutes2[1].route.pattern, 'login');

  //   final locRoutes3 = GoRouter._getLocRouteMatchStack('/family/f2', routes);
  //   expect(locRoutes3.length, 2);
  //   expect(locRoutes3[0].route.pattern, '/');
  //   expect(locRoutes3[1].route.pattern, 'family/:fid');

  //   final locRoutes4 = GoRouter._getLocRouteMatchStack(
  //     '/family/f2/person/p1',
  //     routes,
  //   );
  //   expect(locRoutes4.length, 3);
  //   expect(locRoutes4[0].route.pattern, '/');
  //   expect(locRoutes4[1].route.pattern, 'family/:fid');
  //   expect(locRoutes4[2].route.pattern, 'person/:pid');
  // });

  // test('match too many sub-routes', () {
  //   const loc = '/foo/bar';
  //   final routes = [
  //     GoRoute(
  //       pattern: '/',
  //       builder: _dummy,
  //       routes: [
  //         GoRoute(
  //           pattern: 'foo/bar',
  //           builder: _dummy,
  //         ),
  //         GoRoute(
  //           pattern: 'foo',
  //           builder: _dummy,
  //           routes: [
  //             GoRoute(
  //               pattern: 'bar',
  //               builder: _dummy,
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   ];

  //   try {
  //     GoRouter._getLocRouteMatchStack(loc, routes);
  //     expect(false, true);
  //   } on Exception catch (ex) {
  //     dump(ex);
  //     expect(true, true);
  //   }
  // });
}

GoRouter _router(List<GoRoute> routes) => GoRouter(
      routes: (context, location) => routes,
      error: (context, state) => DummyPage(),
    );

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

class HomePage extends DummyPage {}

class LoginPage extends DummyPage {}

class FamilyPage extends DummyPage {
  final String fid;
  FamilyPage(this.fid);
}

class PersonPage extends DummyPage {}

class DummyPage extends Page<dynamic> {
  @override
  Route createRoute(BuildContext context) => throw UnimplementedError();
}

Page<dynamic> _dummy(BuildContext context, GoRouterState state) => DummyPage();

// ignore: avoid_print
void dump(Object o) => print(o);
