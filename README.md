# go_router
The goal of the go_router package is to simplify use of
[the `Router` in Flutter](https://api.flutter.dev/flutter/widgets/Router-class.html)
as specified by [the
`MaterialApp.router` constructor](https://api.flutter.dev/flutter/material/MaterialApp/MaterialApp.router.html).
By default, it requires an implementation of the
[`RouterDelegate`](https://api.flutter.dev/flutter/widgets/RouterDelegate-class.html) and
[`RouteInformationParser`](https://api.flutter.dev/flutter/widgets/RouteInformationParser-class.html)
classes. These two implementations themselves imply the
definition of a custom type to hold the app state that drives the creation of the
[`Navigator`](https://api.flutter.dev/flutter/widgets/Navigator-class.html).
You can read [an excellent blog post on these requirements on Medium](https://medium.com/flutter/learning-flutters-new-navigation-and-routing-system-7c9068155ade).
This separation of responsibilities allows the Flutter developer to implement a number of routing
and navigation policies at the cost of [complexity](https://www.reddit.com/r/FlutterDev/comments/koxx4w/why_navigator_20_sucks/).

The go_router makes three simplifying assumptions to reduce complexity:
- all routing in the app will happen via URI-compliant names, e.g. `/family/f1/person/p2`
- an entire stack of pages can be constructed from the route name alone, e.g. `FamiliesPage`, `FamilyPage`, `PersonPage`
- the concept of "back" in your app is "up", i.e. going back from `/family/f1/person/p2` goes up to `/family/f1`
  and not back to wherever the user was before they landed on `/family/f1/person/p2`.

These assumptions allow go_router to provide a simpler implementation of your app's custom router.

# Navigation
You can navigate between pages in your app using the `GoRouter.go` method:

```dart
// navigation the hard way
onTap: () => GoRouter.of(context).go('/family/f1/person/p2')
```

The go_router also provides a simplified version using Dart extension methods:

```dart
// navigation the easy way
onTap: () => context.go('/family/f1/person/p2')
```

The simplified version maps directly to the more fully-specified version, so you may use either.

# Imperative Builder
To implement the mapping between a location and a stack of pags, the app can create an instance of the
`GoRouter` class, passing in a builder function to translate from a route name (aka location) into a
`Navigator` The `Navigator` includes a stack of pages and an implementation of `onPopPage`, which handles
calls to `Navigator.pop` and is called by the Flutter implementation of the Back button.

The following is an example implementation of the builder function that supports three pages:
- `FamiliesPage` at `/`
- `FamilyPage` as `/family/:fid`, e.g. `/family/f1`
- `PersonPage` as `/family/:fid/person/:pid`, e.g. `/family/f1/person/p2`

```dart
class App extends StatelessWidget {
  ...
  late final _router = GoRouter(builder: _builder);
  Widget _builder(BuildContext context, String location) {
    final locPages = <String, Page<dynamic>>{};

    try {
      final segments = Uri.parse(location).pathSegments;

      // home page, i.e. '/'
      {
        const loc = '/';
        final page = MaterialPage<FamiliesPage>(
          key: const ValueKey('FamiliesPage'),
          child: FamiliesPage(families: Families.data),
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

      // if we haven't found any matching routes OR
      // if the last route doesn't match exactly, then we haven't got a valid stack of pages;
      // the latter allows '/' to match as part of a stack of pages but to fail on '/nonsense'
      if (locPages.isEmpty || locPages.keys.last.toString().toLowerCase() != location.toLowerCase()) {
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

        // remove the route for the page we're showing and go to the next location up
        locPages.remove(locPages.keys.last);
        _router.go(locPages.keys.last);

        return true;
      },
    );
  }
}
```

There's a lot going on here, but it fundamentally boils down to three things:
1. Matching portions of the location to instances of the app's pages using manually parsed URI segments for
   arguments. This mapping is kept in an ordered map so it can be used as a stack of location=>page mappings.
1. Providing an implementation of `onPopPage` that will translate `Navigation.pop` to use the
   location=>page mappings to navigate to the previous page on the stack.
1. Show an error page if any of that fails.

# Declarative Routes
While the builder implementation above is simpler than providing the three custom type implementations
normally required for routing in a Flutter app, it's still picky and difficult to get right. Also, it's
regular, so it can be simplied into a declarative format using a set of `GoRoute` objects, each matching a
route name pattern, e.g.

```dart
class App extends StatelessWidget {
  ...
  final _router = GoRouter.routes(
    routes: [
      GoRoute(
        pattern: '/',
        builder: (context, args) => MaterialPage<FamiliesPage>(
          key: const ValueKey('FamiliesPage'),
          child: FamiliesPage(families: Families.data),
        ),
      ),
      GoRoute(
        pattern: '/family/:fid',
        builder: (context, args) {
          final family = Families.family(args['fid']!);

          return MaterialPage<FamilyPage>(
            key: ValueKey(family),
            child: FamilyPage(family: family),
          );
        },
      ),
      GoRoute(
        pattern: '/family/:fid/person/:pid',
        builder: (context, args) {
          final family = Families.family(args['fid']!);
          final person = family.person(args['pid']!);

          return MaterialPage<PersonPage>(
            key: ValueKey(person),
            child: PersonPage(family: family, person: person),
          );
        },
      ),
    ],
    error: (context, location, ex) => MaterialPage<Four04Page>(
      key: const ValueKey('ErrorPage'),
      child: Four04Page(message: ex.toString()),
    ),
  );
}
```

In this case, you're doing the same three jobs, but you're doing them w/o a lot of boilerplate:
1. Matching portions of the location to builders to create instance of the app's pages, e.g. `FamiliesPage`
   `FamilyPage`, `PersonPage`, using route name patterns, e.g. `/family/:fid`, so that the go_router can
   parse out the parameters for you. Each pattern is specified in order that the stack of pages will be
   created.
1. The go_router will create the stack of pages for you and implement `onPopPage` using that stack.
1. Show an error page if any of that fails.

The route name patterns are defined and implemented in the [`path_to_regexp`](https://pub.dev/packages/path_to_regexp)
package.

# MaterialApp.router Usage
To configure a `Router` instance for use in your Flutter app, you use the `Material.router` constructor,
passing in the implementation of the `RouterDelegate` and `RouteInformationParser` classes provided by the
`GoRouter` object:

```dart
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: 'GoRouter Example',
      );

  late final _router = GoRouter(...);
  ...
}

```

In this way, go_router can implement the picky custom routing protocol whereas all you have to do
is implement the builder or, even simpler, provide a set of declarative routes.

# URL Path Strategy
By default, Flutter adds a hash (#) into the URL for web apps:

![URL Strategy w/ Hash](readme/url-strat-hash.png)

If you'd like to turn this off using pure Dart and Flutter, you can, but
[this process is a bit picky](https://flutter.dev/docs/development/ui/navigation/url-strategies), too.
The go_router has built-in support for setting the URL path strategy, however, so you can simply call
`GoRouter.setUrlPathStrategy` and make your choice:

```dart
void main() {
  // turn on the # in the URLs on the web (default)
  // GoRouter.setUrlPathStrategy(UrlPathStrategy.hash);

  // turn off the # in the URLs on the web
  GoRouter.setUrlPathStrategy(UrlPathStrategy.path);

  runApp(App());
}
```

Setting the path instead of hash strategy turns off the # in the URLs as expected:

![URL Strategy w/o Hash](readme/url-strat-no-hash.png)

Either way works the same from a routing standpoint, so you can pick the URL path strategy you like the best without
changing any of the rest of your code.

# Examples
You can see the go_router in action via the following examples:
- [`builder.dart`](example/lib/builder.dart): define routing policy by providing a custom builder
- [`routes.dart`](example/lib/routes.dart): define a routing policy but using a set of declarative `GoRoute` objects
- [`url_strategy.dart`](example/lib/url_strategy.dart): turn off the # in the Flutter web URL

You can run these examples from the command line like so:

```sh
flutter run example/lib/builder.dart
```

Or, if you're using Visual Studio Code, a [`launch.json`](.vscode/launch.json) file has been provided with these
examples configured.

# TODO
- test different route groups, e.g. not logged in vs. logged in
  - route guards to redirect when a page requires logging in first
  - updates to the stack as a user goes from logged in/logged out
- test async id => object lookup
- add custom transition support
- nesting routing
- supporting the concept of "back" as well as "up"
- support for shorter locations that result in multiple pages for a single route, e.g. /person?pid=foo
  could end up mapping to three pages (home, families and person) but will only match two routes
  (home and person). The mapping to person requires two pages to be returned (families and person).
- publish
- ...
- profit!
- BUG: navigating back too fast crashes
- BUG: navigation to error page is slow when using package:url_strategy to remove # from URLs
  - "Loading app from service worker"
