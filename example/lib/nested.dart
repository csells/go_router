import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'shared/data.dart';

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
    routes: [
      GoRoute(
        path: '/',
        redirect: (location) => '/family/${Families.data[0].id}',
        routes: [
          GoRoute(
            path: 'family/:fid',
            builder: (context, state) {
              final fid = state.params['fid']!;
              final family = Families.data.firstWhere((f) => f.id == fid);

              return MaterialPage<void>(
                key: state.pageKey,
                child: FamilyTabsPage(
                  key: state.pageKey,
                  currentFamily: family,
                ),
              );
            },
          ),
        ],
      ),
    ],
    
    errorBuilder: _errorBuilder,
  );

  Page<dynamic> _errorBuilder(BuildContext context, GoRouterState state) =>
      MaterialPage<ErrorPage>(
        key: state.pageKey,
        child: ErrorPage(state.error),
      );
}

class FamilyTabsPage extends StatefulWidget {
  final int index;
  FamilyTabsPage({required Family currentFamily, Key? key})
      : index = Families.data.indexWhere((f) => f.id == currentFamily.id),
        super(key: key) {
    assert(index != -1);
  }

  @override
  _FamilyTabsPageState createState() => _FamilyTabsPageState();
}

class _FamilyTabsPageState extends State<FamilyTabsPage>
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_title(context))),
        body: Center(
          child: Column(
            children: [
              TabBar(
                tabs: [for (final f in Families.data) Tab(text: f.name)],
              ),
              Text(Families.data[widget.index].name),
            ],
          ),
        ),
      );

  String _title(BuildContext context) =>
      (context as Element).findAncestorWidgetOfExactType<MaterialApp>()!.title;
}
