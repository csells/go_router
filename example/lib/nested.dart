import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:go_router_examples/shared/data.dart';

import 'shared/pages.dart';

void main() => runApp(App());

/// sample class using simple declarative routes
class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: 'Nested Routes GoRouter Example',
      );

  late final _router = GoRouter(
    routes: _routesBuilder,
    error: _errorBuilder,
    initialLocation: '/family/${Families.data[0].id}',
  );

  List<GoRoute> _routesBuilder(BuildContext context, String location) => [
        GoRoute(
          path: '/',
          builder: (context, state) => MaterialPage<void>(
            key: state.pageKey,
            child: ScaffoldPage(child: state.child!),
          ),
          nested: [
            GoNestedRoute(
              path: 'family/:fid',
              builder: (context, state) => FamiliesView(
                key: state.pageKey,
                selectedFid: state.params['fid']!,
              ),
            ),
          ],
        ),
      ];

  Page<dynamic> _errorBuilder(BuildContext context, GoRouterState state) =>
      MaterialPage<ErrorPage>(
        key: state.pageKey,
        child: ErrorPage(state.error),
      );
}

class ScaffoldPage extends StatelessWidget {
  final Widget child;
  const ScaffoldPage({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_title(context))),
        body: child,
      );

  String _title(BuildContext context) =>
      (context as Element).findAncestorWidgetOfExactType<MaterialApp>()!.title;
}

class FamiliesView extends StatefulWidget {
  late final int index;
  FamiliesView({required String selectedFid, Key? key}) : super(key: key) {
    index = Families.data.indexWhere((f) => f.id == selectedFid);
    if (index == -1) throw Exception('unknown fid: $selectedFid');
  }

  @override
  _FamiliesViewState createState() => _FamiliesViewState();
}

class _FamiliesViewState extends State<FamiliesView>
    with TickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: Families.data.length,
      vsync: this,
      initialIndex: widget.index,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          children: [
            TabBar(
              tabs: [for (final f in Families.data) Tab(text: f.name)],
            ),
            Text(Families.data[widget.index].name),
          ],
        ),
      );
}
