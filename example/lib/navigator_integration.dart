// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shared/data.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  static const title = 'GoRouter Example: Navigator Integration';

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: title,
        debugShowCheckedModeBanner: false,
      );

  late final _router = GoRouter(
    routes: [
      GoRoute(
        name: 'home',
        path: '/',
        builder: (context, state) => HomePage(families: Families.data),
        routes: [
          GoRoute(
            name: 'family',
            path: 'family/:fid',
            builder: (context, state) => FamilyPageWithAdd(
              family: Families.family(state.params['fid']!),
            ),
            routes: [
              GoRoute(
                name: 'person',
                path: 'person/:pid',
                builder: (context, state) {
                  final family = Families.family(state.params['fid']!);
                  final person = family.person(state.params['pid']!);
                  return PersonPage(family: family, person: person);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class HomePage extends StatelessWidget {
  const HomePage({required this.families, Key? key}) : super(key: key);
  final List<Family> families;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(App.title)),
        body: ListView(
          children: [
            for (final f in families)
              ListTile(
                title: Text(f.name),
                onTap: () => context.goNamed('family', params: {'fid': f.id}),
              )
          ],
        ),
      );
}

class FamilyPageWithAdd extends StatefulWidget {
  const FamilyPageWithAdd({required this.family, Key? key}) : super(key: key);
  final Family family;

  @override
  State<FamilyPageWithAdd> createState() => _FamilyPageWithAddState();
}

class _FamilyPageWithAddState extends State<FamilyPageWithAdd> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.family.name),
          actions: [
            IconButton(
              onPressed: () => _addPerson(context),
              tooltip: 'Add Person',
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: ListView(
          children: [
            for (final p in widget.family.people)
              ListTile(
                title: Text(p.name),
                onTap: () => context.go(context.namedLocation(
                  'person',
                  params: {'fid': widget.family.id, 'pid': p.id},
                  queryParams: {'qid': 'quid'},
                )),
              ),
          ],
        ),
      );

  Future<void> _addPerson(BuildContext context) async {
    final person = await Navigator.push<Person>(
      context,
      MaterialPageRoute(
        builder: (context) => NewPersonPage(family: widget.family),
      ),
    );

    if (person != null) {
      setState(() => widget.family.people.add(person));
      context.goNamed('person', params: {
        'fid': widget.family.id,
        'pid': person.id,
      });
    }
  }
}

class PersonPage extends StatelessWidget {
  const PersonPage({required this.family, required this.person, Key? key})
      : super(key: key);

  final Family family;
  final Person person;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(person.name)),
        body: Text('${person.name} ${family.name} is ${person.age} years old'),
      );
}

class NewPersonPage extends StatefulWidget {
  const NewPersonPage({required this.family, Key? key}) : super(key: key);
  final Family family;

  @override
  State<NewPersonPage> createState() => _NewPersonPageState();
}

class _NewPersonPageState extends State<NewPersonPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _nameController.dispose();
    _ageController.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('New person for family ${widget.family.name}'),
        ),
        body: Form(
          key: _formKey,
          child: Center(
            child: SizedBox(
              width: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'name'),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter a name'
                        : null,
                  ),
                  TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(labelText: 'age'),
                    validator: (value) => value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null
                        ? 'Please enter an age'
                        : null,
                  ),
                  ButtonBar(children: [
                    TextButton(
                      // just like Navigator.pop(context),
                      onPressed: () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final person = Person(
                            id: 'p${widget.family.people.length + 1}',
                            name: _nameController.text,
                            age: int.parse(_ageController.text),
                          );

                          Navigator.pop(context, person);
                        }
                      },
                      child: const Text('Create'),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      );
}
