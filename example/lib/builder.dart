import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shared/data.dart';
import 'shared/pages.dart';

void main() => runApp(App());

/// sample app using a customer GoRouter builder
class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: 'Builder GoRouter Example',
      );

  late final _router = GoRouter.builder(builder: _builder);
  Widget _builder(BuildContext context, String location) {
    final locPages = <String, Page<dynamic>>{};

    try {
      final segments = Uri.parse(location).pathSegments;

      // home page, i.e. '/'
      {
        const loc = '/';
        final page = MaterialPage<HomePage>(
          key: const ValueKey('HomePage'),
          child: HomePage(families: Families.data),
        );
        locPages[loc] = page;
      }

      // family page, e.g. '/family/:fid
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

      // person page, e.g. '/family/:fid/person/:pid
      if (segments.length >= 4 &&
          segments[0] == 'family' &&
          segments[2] == 'person') {
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

      // if we haven't found any matching routes OR if the last route doesn't
      // match exactly, then we haven't got a valid stack of pages; the latter
      // allows '/' to match as part of a stack of pages but to fail on
      // '/nonsense'
      if (locPages.isEmpty ||
          locPages.keys.last.toString().toLowerCase() !=
              location.toLowerCase()) {
        throw Exception('page not found: $location');
      }
    } on Exception catch (error) {
      locPages.clear();

      final loc = location;
      final page = MaterialPage<ErrorPage>(
        key: const ValueKey('ErrorPage'),
        child: ErrorPage(error),
      );

      locPages[loc] = page;
    }

    return Navigator(
      pages: locPages.values.toList(),
      onPopPage: (route, dynamic result) {
        if (!route.didPop(result)) return false;

        // remove the route for the page we're showing and go to the next
        // location up
        locPages.remove(locPages.keys.last);
        _router.go(locPages.keys.last);

        return true;
      },
    );
  }
}
