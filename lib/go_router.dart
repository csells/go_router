library go_router;

import 'dart:collection';
import 'package:flutter/widgets.dart';
import 'package:path_to_regexp/path_to_regexp.dart' as p2re;

import 'src/go_router_impl.dart';
import 'src/path_strategy_nonweb.dart' if (dart.library.html) 'src/path_strategy_web.dart';

enum UrlPathStrategy { hash, path }
typedef GoRouteBuilder = Widget Function(BuildContext context, String location);
typedef GoRouteInfoBuilder = List<GoRoute> Function(BuildContext context);
typedef GoRoutePageBuilder = Page<dynamic> Function(BuildContext context, Map<String, String> args);
typedef GoRouteErrorPageBuilder = Page<dynamic> Function(BuildContext context, String location, Exception ex);

class GoRoute {
  final String pattern;
  final GoRoutePageBuilder builder;
  GoRoute({required this.pattern, required this.builder});
}

class GoRouter {
  final _routeInformationParser = GoRouteInformationParser();
  late final GoRouterDelegate _routerDelegate;
  final _locsForPopping = Stack<Uri>();

  GoRouter({required GoRouteBuilder builder}) {
    _routerDelegate = GoRouterDelegate(
      // wrap the returned Navigator to enable GoRouter.of(context).go() and context.go()
      builder: (context, location) => InheritedGoRouter(
        goRouter: this,
        child: builder(context, location),
      ),
    );
  }

  // GoRouter.routes({required List<GoRoute> routes, required GoRouteErrorPageBuilder error})
  //     : this(builder: (context) => routes, error: error);

  RouteInformationParser<Object> get routeInformationParser => _routeInformationParser;
  RouterDelegate<Object> get routerDelegate => _routerDelegate;

  void go(String location) {
    _routerDelegate.go(location);
  }

  static void setUrlPathStrategy(UrlPathStrategy strategy) => setUrlPathStrategyImpl(strategy);
  static String locationFor(String pattern, Map<String, String> args) => p2re.pathToFunction(pattern)(args);
  static GoRouter of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<InheritedGoRouter>()!.goRouter;

  // Widget _builder(BuildContext context, String location, List<GoRoute> routes, GoRouteErrorPageBuilder error) {
  //   final locPages = <Uri, Page<dynamic>>{};
  //   Exception? ex;

  //   for (final info in routes) {
  //     final params = <String>[];
  //     final re = p2re.pathToRegExp(info.pattern, prefix: true, caseSensitive: false, parameters: params);
  //     final match = re.matchAsPrefix(location);
  //     if (match == null) continue;

  //     final args = p2re.extract(params, match);
  //     final pageLoc = GoRouter.locationFor(info.pattern, args);

  //     try {
  //       final page = info.builder(context, args);
  //       final uri = Uri.parse(pageLoc);
  //       if (locPages.containsKey(uri)) throw Exception('duplicate location: $pageLoc');
  //       locPages[Uri.parse(pageLoc)] = page;
  //     } on Exception catch (ex2) {
  //       // if can't add a page from their args, show an error
  //       ex = ex2;
  //       break;
  //     }
  //   }

  //   // if the last route doesn't match exactly, then we haven't got a valid stack of pages;
  //   // this allows '/' to match as part of a stack of pages but to fail on '/nonsense'
  //   if (location.toLowerCase() != locPages.keys.last.toString().toLowerCase()) locPages.clear();

  //   // if no pages found, show an error
  //   if (locPages.isEmpty) ex = Exception('page not found: $location');

  //   // if there's an error, show an error page
  //   if (ex != null) {
  //     locPages.clear();
  //     locPages[Uri.parse(location)] = error(context, location, ex);
  //   }

  //   // keep the stack of locations for onPopPage
  //   _locsForPopping.clear();
  //   _locsForPopping.addAll(locPages.keys);

  //   return Navigator(
  //     pages: locPages.values.toList(),
  //     onPopPage: (route, dynamic result) {
  //       if (!route.didPop(result)) return false;

  //       assert(_locsForPopping.depth >= 1);
  //       _locsForPopping.pop(); // remove the route for the page we're showing
  //       go(_locsForPopping.top.toString()); // go to the location for the next page down

  //       return true;
  //     },
  //   );
  // }
}

extension GoRouterHelper on BuildContext {
  void go(String location) {
    GoRouter.of(this).go(location);
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
