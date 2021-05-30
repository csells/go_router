import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:path_to_regexp/path_to_regexp.dart';

import 'data.dart';
import 'pages.dart';

void main() {
  // turn off the # in the URLs on the web
  // GoRouter.setUrlPathStrategy(UrlPathStrategy.path);

  runApp(App());
}

class App extends StatelessWidget {
  late final _router = GoRouter(builder: _builder);

  App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: 'Builder-Up GoRouter Example',
      );

  Widget _builder(BuildContext context, String location) {
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
      // this allows '/' to match as part of a stack of pages but to fail on '/nonsense'
      if (location.toLowerCase() != locPages.keys.last.toString().toLowerCase()) locPages.clear();

      if (locPages.isEmpty) throw Exception('page not found: $location');
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

        locPages.remove(locPages.keys.last); // remove the route for the page we're showing
        _router.go(locPages.keys.last.toString()); // go to the location for the next page down

        return true;
      },
    );
  }

  // final _router = GoRouter.routes(
  //   routes: [
  //     GoRoute(
  //       pattern: '/',
  //       builder: (context, args) => MaterialPage<FamiliesPage>(
  //         key: const ValueKey('FamiliesPage'),
  //         child: FamiliesPage(families: Families.data),
  //       ),
  //     ),
  //     GoRoute(
  //       pattern: '/family/:fid',
  //       builder: (context, args) {
  //         final family = Families.family(args['fid']!);

  //         return MaterialPage<FamilyPage>(
  //           key: ValueKey(family),
  //           child: FamilyPage(family: family),
  //         );
  //       },
  //     ),
  //     GoRoute(
  //       pattern: '/family/:fid/person/:pid',
  //       builder: (context, args) {
  //         final family = Families.family(args['fid']!);
  //         final person = family.person(args['pid']!);

  //         return MaterialPage<PersonPage>(
  //           key: ValueKey(person),
  //           child: PersonPage(family: family, person: person),
  //         );
  //       },
  //     ),
  //   ],
  // error: (context, location, ex) => MaterialPage<Four04Page>(
  //   key: const ValueKey('ErrorPage'),
  //   child: Four04Page(message: ex.toString()),
  // ),
  // );
}
