import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:path_to_regexp/path_to_regexp.dart' as p2re;

import '../go_router.dart';

class GoRouterDelegate extends RouterDelegate<Uri>
    with
        PopNavigatorRouterDelegateMixin<Uri>,
        // ignore: prefer_mixin
        ChangeNotifier {
  Uri _loc = Uri.parse('/');
  final _key = GlobalKey<NavigatorState>();
  final _locsForPopping = Stack<Uri>();
  final GoRouter goRouter;

  GoRouterDelegate({required this.goRouter});

  @override
  GlobalKey<NavigatorState> get navigatorKey => _key;

  @override
  Uri get currentConfiguration => _loc;

  void go(String route) {
    _loc = Uri.parse(route);
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    // final locationPages = <LocPageInfo>[];
    final locPages = <Uri, Page<dynamic>>{};
    final location = _loc.toString().trim();
    final infos = goRouter.builder(context);
    Exception? ex;

    for (final info in infos) {
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
      locPages[Uri.parse(location)] = goRouter.error(context, location, ex);
    }

    // keep the stack of locations for onPopPage
    _locsForPopping.clear();
    _locsForPopping.addAll(locPages.keys);

    // wrap the returned Navigator to enable GoRouter.of(context).go() and context.go()
    return InheritedGoRouter(
      goRouter: goRouter,
      child: Navigator(
        pages: locPages.values.toList(),
        onPopPage: (route, dynamic result) {
          if (!route.didPop(result)) return false;

          assert(_locsForPopping.depth >= 1);
          _locsForPopping.pop(); // remove the route for the page we're showing
          _loc = _locsForPopping.top; // set the route for the next page down
          notifyListeners();

          return true;
        },
      ),
    );
  }

  @override
  Future<void> setNewRoutePath(Uri configuration) async {
    _loc = configuration;
  }
}

class GoRouteInformationParser extends RouteInformationParser<Uri> {
  @override
  Future<Uri> parseRouteInformation(RouteInformation routeInformation) async =>
      Uri.parse(routeInformation.location ?? '/');

  @override
  RouteInformation restoreRouteInformation(Uri configuration) => RouteInformation(location: configuration.toString());
}

class InheritedGoRouter extends InheritedWidget {
  final GoRouter goRouter;
  const InheritedGoRouter({required Widget child, required this.goRouter, Key? key}) : super(child: child, key: key);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;
}

class LocPageInfo {
  final String location;
  final Page<dynamic> page;
  LocPageInfo({required this.location, required this.page}) {
    Uri.parse(location);
  }
}

class Stack<T> {
  final _queue = Queue<T>();

  Stack([Iterable<T>? init]) {
    if (init != null) _queue.addAll(init);
  }

  void push(T item) => _queue.addLast(item);
  void addAll(Iterable<T> items) => _queue.addAll(items);
  T get top => _queue.last;
  int get depth => _queue.length;
  T pop() => _queue.removeLast();
  void clear() => _queue.clear();
  bool get isEmpty => _queue.isEmpty;
  bool get isNotEmpty => _queue.isNotEmpty;
}
