import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data.dart';
import 'pages.dart';

void main() {
  // turn off the # in the URLs on the web
  // GoRouter.setUrlPathStrategy(UrlPathStrategy.path);

  runApp(App());
}

class App extends StatelessWidget {
  static const title = 'Builder-Up GoRouter Example';
  App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: App.title,
      );

  late final _router = GoRouter(builder: _builder);
  Widget _builder(BuildContext context, String location) {
    print('location= $location');
    final locPages = <String, Page<dynamic>>{};

    try {
      final segments = (Uri.tryParse(location) ?? Uri.parse('/')).pathSegments;

      // home page, i.e. '/'
      {
        const loc = '/';
        final page = MaterialPage<FamiliesPage>(
          key: const ValueKey('FamiliesPage'),
          child: FamiliesPage(families: Families.data),
        );
        locPages[loc] = page;
      }

      // family page, e.g. '/family/{fid}
      if (segments.length >= 2 && segments[0] == 'family') {
        final fid = segments[1];
        final family = Families.family(fid);

        final loc = '/family/$fid';
        final page = MaterialPage<FamilyPage>(
          key: ValueKey(family),
          child: FamilyPage(family: family),
        );

        locPages[loc] = page;
      }

      // person page, e.g. '/family/{fid}/person/{pid}
      if (segments.length >= 4 && segments[0] == 'family' && segments[2] == 'person') {
        final fid = segments[1];
        final pid = segments[3];
        final family = Families.family(fid);
        final person = family.person(pid);

        final loc = '/family/$fid/person/$pid';
        final page = MaterialPage<PersonPage>(
          key: ValueKey(person),
          child: PersonPage(family: family, person: person),
        );

        locPages[loc] = page;
      }

      // if the last route doesn't match exactly, then we haven't got a valid stack of pages;
      // this allows '/' to match as part of a stack of pages but to fail on '/nonsense' OR
      // if we haven't found any matching routes, then we have an error
      if (locPages.keys.last.toString().toLowerCase() != location.toLowerCase() || locPages.isEmpty) {
        throw Exception('page not found: $location');
      }
    } on Exception catch (ex) {
      locPages.clear();

      final loc = location;
      final page = MaterialPage<Four04Page>(
        key: const ValueKey('ErrorPage'),
        child: Four04Page(message: ex.toString()),
      );

      locPages[loc] = page;
    }

    return Navigator(
      pages: locPages.values.toList(),
      onPopPage: (route, dynamic result) {
        if (!route.didPop(result)) return false;

        // remove the route for the page we're showing and go to the next location down
        locPages.remove(locPages.keys.last);
        _router.go(locPages.keys.last);

        return true;
      },
    );
  }
}
