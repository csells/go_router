import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'data.dart';

String _title(BuildContext context) =>
    (context as Element).findAncestorWidgetOfExactType<MaterialApp>()!.title;

/// sample page to show home
class Page1Page extends StatelessWidget {
  const Page1Page({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_title(context))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => context.go('/page2'),
                child: const Text('Go to page 2'),
              ),
            ],
          ),
        ),
      );
}

/// sample page
class Page2Page extends StatelessWidget {
  const Page2Page({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_title(context))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go to home page'),
              ),
            ],
          ),
        ),
      );
}

/// sample page
class Page3Page extends StatelessWidget {
  const Page3Page({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_title(context))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => context.go('/page2'),
                child: const Text('Go to page 2'),
              ),
            ],
          ),
        ),
      );
}

/// sample page to show families
class HomePage extends StatelessWidget {
  final List<Family> families;
  const HomePage({required this.families, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final info = _info(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title(context)),
        actions: [
          if (info != null)
            IconButton(
              onPressed: info.logout,
              tooltip: 'Logout: ${info.userName}',
              icon: const Icon(Icons.logout),
            )
        ],
      ),
      body: ListView(
        children: [
          for (final f in families)
            ListTile(
              title: Text(f.name),
              onTap: () => context.go('/family/${f.id}'),
            )
        ],
      ),
    );
  }

  LoginInfo? _info(BuildContext context) {
    try {
      return context.read<LoginInfo>();
    } on Exception catch (_) {
      return null;
    }
  }
}

/// sample page to show a single family
class FamilyPage extends StatelessWidget {
  final Family family;
  const FamilyPage({required this.family, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(family.name)),
        body: ListView(
          children: [
            for (final p in family.people)
              ListTile(
                title: Text(p.name),
                onTap: () => context.go('/family/${family.id}/person/${p.id}'),
              ),
          ],
        ),
      );
}

/// sample page to show a single person
class PersonPage extends StatelessWidget {
  final Family family;
  final Person person;
  const PersonPage({required this.family, required this.person, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(person.name)),
        body: Text('${person.name} ${family.name} is ${person.age} years old'),
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.index = widget.index;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(_title(context)),
          bottom: TabBar(
            controller: _controller,
            tabs: [for (final f in Families.data) Tab(text: f.name)],
            onTap: (index) => _tap(context, index),
          ),
        ),
        body: TabBarView(
          controller: _controller,
          children: [for (final f in Families.data) FamilyView(family: f)],
        ),
      );

  void _tap(BuildContext context, int index) =>
      context.go('/family/${Families.data[index].id}');

  String _title(BuildContext context) =>
      (context as Element).findAncestorWidgetOfExactType<MaterialApp>()!.title;
}

class FamilyView extends StatelessWidget {
  final Family family;
  const FamilyView({required this.family, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => ListView(
        children: [
          for (final p in family.people) ListTile(title: Text(p.name)),
        ],
      );
}

/// sample error page
class ErrorPage extends StatelessWidget {
  final Exception? error;
  const ErrorPage(this.error, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error?.toString() ?? 'page not found'),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Home'),
              ),
            ],
          ),
        ),
      );
}

/// sample login page
class LoginPage extends StatelessWidget {
  final String? from;
  const LoginPage({this.from, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_title(context))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  // log a user in, letting all the listeners know
                  context.read<LoginInfo>().login('test-user');

                  // if there's a deep link, go there
                  if (from != null) context.go(from!);
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
}
