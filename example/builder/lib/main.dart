import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_to_regexp/path_to_regexp.dart';

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
        title: 'Simplest GoRouter Example',
      );

  Widget _builder(BuildContext context, String location) {
    final locPages = <Uri, Page<dynamic>>{};
    Exception? ex;

    for (final info in routes) {
      final params = <String>[];
      final re = p2re.pathToRegExp(info.pattern, prefix: true, caseSensitive: false, parameters: params);
      final match = re.matchAsPrefix(location);
      if (match == null) continue;

      final args = p2re.extract(params, match);
      final pageLoc = GoRouter.locationFor(info.pattern, args);

      try {
        final page = info.builder(context, args);
        final uri = Uri.parse(pageLoc);
        if (locPages.containsKey(uri)) throw Exception('duplicate location: $pageLoc');
        locPages[Uri.parse(pageLoc)] = page;
      } on Exception catch (ex2) {
        // if can't add a page from their args, show an error
        ex = ex2;
        break;
      }
    }

    // if the last route doesn't match exactly, then we haven't got a valid stack of pages;
    // this allows '/' to match as part of a stack of pages but to fail on '/nonsense'
    if (location.toLowerCase() != locPages.keys.last.toString().toLowerCase()) locPages.clear();

    // if no pages found, show an error
    if (locPages.isEmpty) ex = Exception('page not found: $location');

    // if there's an error, show an error page
    if (ex != null) {
      locPages.clear();
      locPages[Uri.parse(location)] = error(context, location, ex);
    }

    // keep the stack of locations for onPopPage
    _locsForPopping.clear();
    _locsForPopping.addAll(locPages.keys);

    return  Navigator(
        pages: locPages.values.toList(),
        onPopPage: (route, dynamic result) {
          if (!route.didPop(result)) return false;

          assert(_locsForPopping.depth >= 1);
          _locsForPopping.pop(); // remove the route for the page we're showing
          go(_locsForPopping.top.toString()); // go to the location for the next page down

          return true;
        },
      ),
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
