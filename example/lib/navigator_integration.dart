// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'shared/data.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  final loginInfo = LoginInfo();

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<LoginInfo>.value(
        value: loginInfo,
        child: MaterialApp.router(
          routeInformationParser: _router.routeInformationParser,
          routerDelegate: _router.routerDelegate,
          title: 'GoRouter Example: Navigator Integration',
          debugShowCheckedModeBanner: false,
        ),
      );

  late final _router = GoRouter(
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        name: 'home',
        path: '/',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: HomePage(families: Families.data),
        ),
        routes: [
          GoRoute(
            name: 'family',
            path: 'family/:fid',
            pageBuilder: (context, state) {
              final family = Families.family(state.params['fid']!);
              return MaterialPage<void>(
                key: state.pageKey,
                child: FamilyPageWithAdd(family: family),
              );
            },
            routes: [
              GoRoute(
                name: 'person',
                path: 'person/:pid',
                pageBuilder: (context, state) {
                  final family = Families.family(state.params['fid']!);
                  final person = family.person(state.params['pid']!);
                  return MaterialPage<void>(
                    key: state.pageKey,
                    child: PersonPage(family: family, person: person),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        name: 'login',
        path: '/login',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          // pass the original location to the LoginPage (if there is one)
          child: LoginPage(from: state.queryParams['from']),
        ),
      ),
    ],

    errorPageBuilder: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      child: ErrorPage(state.error),
    ),

    // redirect to the login page if the user is not logged in
    redirect: (state) {
      final loggedIn = loginInfo.loggedIn;

      // check just the subloc in case there are query parameters
      final loginLoc = state.namedLocation('login');
      final goingToLogin = state.subloc == loginLoc;

      // the user is not logged in and not headed to /login, they need to login
      if (!loggedIn && !goingToLogin) {
        return state.namedLocation(
          'login',
          queryParams: {'from': state.subloc},
        );
      }

      // the user is logged in and headed to /login, no need to login again
      if (loggedIn && goingToLogin) return state.namedLocation('home');

      // no need to redirect at all
      return null;
    },

    // changes on the listenable will cause the router to refresh it's route
    refreshListenable: loginInfo,
  );
}

String _title(BuildContext context) =>
    (context as Element).findAncestorWidgetOfExactType<MaterialApp>()!.title;

class HomePage extends StatelessWidget {
  const HomePage({required this.families, Key? key}) : super(key: key);
  final List<Family> families;

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
              onTap: () => context.goNamed('family', params: {'fid': f.id}),
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

class ErrorPage extends StatelessWidget {
  const ErrorPage(this.error, {Key? key}) : super(key: key);
  final Exception? error;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SelectableText(error?.toString() ?? 'page not found'),
              TextButton(
                onPressed: () => context.goNamed('home'),
                child: const Text('Home'),
              ),
            ],
          ),
        ),
      );
}

class LoginPage extends StatelessWidget {
  const LoginPage({this.from, Key? key}) : super(key: key);
  final String? from;

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
