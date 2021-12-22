// ignore_for_file: use_late_for_private_fields_and_variables

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shared/data.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  static const title = 'GoRouter Example: Async Data';
  static final repo = Repository();

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: title,
      );

  late final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreenWithAsync(),
        routes: [
          GoRoute(
            path: 'family/:fid',
            builder: (context, state) => FamilyScreenWithAsync(
              fid: state.params['fid']!,
            ),
            routes: [
              GoRoute(
                path: 'person/:pid',
                builder: (context, state) => PersonScreenWithAsync(
                  fid: state.params['fid']!,
                  pid: state.params['pid']!,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class HomeScreenWithAsync extends StatefulWidget {
  const HomeScreenWithAsync({Key? key}) : super(key: key);

  @override
  State<HomeScreenWithAsync> createState() => _HomeScreenWithAsyncState();
}

class _HomeScreenWithAsyncState extends State<HomeScreenWithAsync> {
  Future<List<Family>>? _future;
  List<Family>? _families;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  @override
  void didUpdateWidget(covariant HomeScreenWithAsync oldWidget) {
    super.didUpdateWidget(oldWidget);

    // refresh cached data
    //fetch(); // no need
  }

  void fetch() {
    _families = null;
    _future = App.repo.getFamilies();
    _future!.then(
      (families) {
        if (mounted) setState(() => _families = families); // update AppBar
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            '${App.title}: ${_families != null ? '${_families!.length} '
                'families' : 'loading...'}',
          ),
        ),
        body: FutureBuilder<List<Family>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) return SnapshotError(snapshot.error!);

            assert(snapshot.hasData);
            return ListView(
              children: [
                for (final f in _families!)
                  ListTile(
                    title: Text(f.name),
                    onTap: () => context.go('/family/${f.id}'),
                  )
              ],
            );
          },
        ),
      );
}

class FamilyScreenWithAsync extends StatefulWidget {
  const FamilyScreenWithAsync({required this.fid, Key? key}) : super(key: key);
  final String fid;

  @override
  State<FamilyScreenWithAsync> createState() => _FamilyScreenWithAsyncState();
}

class _FamilyScreenWithAsyncState extends State<FamilyScreenWithAsync> {
  Future<Family>? _future;
  Family? _family;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  @override
  void didUpdateWidget(covariant FamilyScreenWithAsync oldWidget) {
    super.didUpdateWidget(oldWidget);

    // refresh cached data
    if (oldWidget.fid != widget.fid) fetch();
  }

  void fetch() {
    _family = null;
    _future = App.repo.getFamily(widget.fid);
    _future!.then(
      (family) {
        if (mounted) setState(() => _family = family); // update AppBar
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_family?.name ?? 'loading...')),
        body: FutureBuilder<Family>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) return SnapshotError(snapshot.error!);

            assert(snapshot.hasData);
            return ListView(
              children: [
                for (final p in _family!.people)
                  ListTile(
                    title: Text(p.name),
                    onTap: () =>
                        context.go('/family/${_family!.id}/person/${p.id}'),
                  ),
              ],
            );
          },
        ),
      );
}

class PersonScreenWithAsync extends StatefulWidget {
  const PersonScreenWithAsync({required this.fid, required this.pid, Key? key})
      : super(key: key);

  final String fid;
  final String pid;

  @override
  State<PersonScreenWithAsync> createState() => _PersonScreenWithAsyncState();
}

class _PersonScreenWithAsyncState extends State<PersonScreenWithAsync> {
  Future<FamilyPerson>? _future;
  FamilyPerson? _famper;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  @override
  void didUpdateWidget(covariant PersonScreenWithAsync oldWidget) {
    super.didUpdateWidget(oldWidget);

    // refresh cached data
    if (oldWidget.fid != widget.fid || oldWidget.pid != widget.pid) fetch();
  }

  void fetch() {
    _famper = null;
    _future = App.repo.getPerson(widget.fid, widget.pid);
    _future!.then(
      (famper) {
        if (mounted) setState(() => _famper = famper); // update AppBar
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_famper?.person.name ?? 'loading...')),
        body: FutureBuilder<FamilyPerson>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) return SnapshotError(snapshot.error!);

            assert(snapshot.hasData);
            return Text(
              '${_famper!.person.name} ${_famper!.family.name} is '
              '${_famper!.person.age} years old',
            );
          },
        ),
      );
}

class SnapshotError extends StatelessWidget {
  SnapshotError(Object error, {Key? key})
      : error = error is Exception ? error : Exception(error),
        super(key: key);
  final Exception error;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SelectableText(error.toString()),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Home'),
            ),
          ],
        ),
      );
}
