import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'data.dart';

String _title(BuildContext context) => (context as Element).findAncestorWidgetOfExactType<MaterialApp>()!.title;

class FamiliesPage extends StatelessWidget {
  final List<Family> families;
  const FamiliesPage({required this.families, Key? key}) : super(key: key);

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

class PersonPage extends StatelessWidget {
  final Family family;
  final Person person;
  const PersonPage({required this.family, required this.person, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(person.name)),
        body: Text('${person.name} ${family.name} is ${person.age} years old'),
      );
}

class Four04Page extends StatelessWidget {
  final String message;
  const Four04Page({required this.message, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(message),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Home'),
              ),
            ],
          ),
        ),
      );
}

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_title(context))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                // log a user in, letting all the listeners know
                onPressed: () => context.read<LoginInfo>().login('user1'),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
}
