[![Pub
Version](https://img.shields.io/pub/v/go_router?label=go_router&labelColor=333940&logo=dart)](https://pub.dev/packages/go_router)
![Test](https://github.com/csells/go_router/workflows/validate/badge.svg)
[![codecov](https://codecov.io/gh/csells/go_router/branch/master/graph/badge.svg?token=4XJU30IGO3)](https://codecov.io/gh/csells/go_router)
[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

# Welcome to go_router!

The goal of the [go_router package](https://pub.dev/packages/go_router) is to
simplify use of [the `Router` in
Flutter](https://api.flutter.dev/flutter/widgets/Router-class.html) as specified
by [the `MaterialApp.router`
constructor](https://api.flutter.dev/flutter/material/MaterialApp/MaterialApp.router.html).
By default, it requires an implementation of the
[`RouterDelegate`](https://api.flutter.dev/flutter/widgets/RouterDelegate-class.html)
and
[`RouteInformationParser`](https://api.flutter.dev/flutter/widgets/RouteInformationParser-class.html)
classes. These two implementations themselves imply the definition of a third
type to hold the app state that drives the creation of the
[`Navigator`](https://api.flutter.dev/flutter/widgets/Navigator-class.html). You
can read [an excellent blog post on these requirements on
Medium](https://medium.com/flutter/learning-flutters-new-navigation-and-routing-system-7c9068155ade).
This separation of responsibilities allows the Flutter developer to implement a
number of routing and navigation policies, including deep and dynamic linking,
but at the cost of
[complexity](https://www.reddit.com/r/FlutterDev/comments/koxx4w/why_navigator_20_sucks/).

The purpose of the go_router is to use declarative routes to reduce complexity,
regardless of the platform you're targeting (mobile, web, desktop), handling
deep and dynamic linking from Android, iOS and the web, along with a number of
other navigation-related scenarios, while still (hopefully) providing an
easy-to-use developer experience.

# Table of Contents

- [Contributors](#contributors)
- [Changelog](#changelog)
- [Migrating to 2.x](#migrating-to-2x)
- [Getting Started](#getting-started)
- [Video Overview](#video-overview)
- [Declarative Routing](#declarative-routing)
  - [Router state](#router-state)
  - [Error handling](#error-handling)
  - [Initialization](#initialization)
- [Navigation](#navigation)
  - [Current location](#current-location)
- [Initial Location](#initial-location)
- [Parameters](#parameters)
  - [Dynamic linking](#dynamic-linking)
- [Sub-routes](#sub-routes)
- [Pushing pages](#pushing-pages)
  - [Popping pages](#popping-pages)
- [Redirection](#redirection)
  - [Top-level redirection](#top-level-redirection)
  - [Route-level redirection](#route-level-redirection)
  - [Parameterized redirection](#parameterized-redirection)
  - [Multiple redirections](#multiple-redirections)
- [Query Parameters](#query-parameters)
- [Extra Parameter](#extra-parameter)
- [Named Routes](#named-routes)
  - [Navigating to Named Routes](#navigating-to-named-routes)
  - [Redirecting to Named Routes](#redirecting-to-named-routes)
- [Custom Transitions](#custom-transitions)
- [Async Data](#async-data)
- [Nested Navigation](#nested-navigation)
  - [Keeping State](#keeping-state)
- [Navigator Builder](#navigator-builder)
- [Deep Linking](#deep-linking)
- [URL Path Strategy](#url-path-strategy)
- [Debugging Your Routes](#debugging-your-routes)
- [Navigator Integration](#navigator-integration)
- [Examples](#examples)
- [Issues](#issues)

# Contributors

It's amazing to me how many folks have already contributed to this project. Huge
shout out to the go_router contributors!

- [Salakar](https://github.com/Salakar) for the CI action on
  GitHub that is always helping me track down stuff I forget
- [rydmike](https://github.com/rydmike) for a bunch of README and dartdoc fixes
  as well as a great example for keeping state during nested navigation
- [Abhishek01039](https://github.com/Abhishek01039) for helping me change a
  life-long habit of sorting constructors after fields, which goes against Dart
  best practices
- [SunlightBro](https://github.com/SunlightBro) for the Android system Back
  button fix
- [craiglabenz](https://github.com/craiglabenz) for a bunch of README fixes;
  also, Craig has been talking about adding build_runner support to
  produce typesafe go and push code for named routes, so thumbs up on [this
  issues](https://github.com/csells/go_router/issues/66) if that's a feature
  you'd like to see in go_router
- [kevmoo](https://github.com/kevmoo) for helping me track down spelling issues
  in my README and unused imports and refactoring for easier maintenance
- [andyduke](https://github.com/andyduke) for [the most excellent
  navigationBuilder feature](#navigator-builder) and updates to [state
  restoration](https://github.com/csells/go_router/blob/master/example/lib/state_restoration.dart).
- [lulupointu](https://github.com/lulupointu) for deep link fixes that keep
  pages from flashing willy-nilly.

# Changelog

If you'd like to see what's changed in detail over time, you can read [the
go_router Changelog](https://pub.dev/packages/go_router/changelog).

# Migrating to 2.x

By [popular demand](https://twitter.com/csells/status/1445520767190388738),
there is a breaking change in the go_router 2.0 release: the `params` property
of the `GoRouterState` object has been split into two properties:

- `params` for parameters that are part of the path and, e.g. `/family/:fid`
- `queryParams` for parameters that added optionally at the end of the location,
  e.g. `/login?from=/family/f2`

In the 1.x releases, the `params` property was a single object that contained
both the path and query parameters in a single map. For example, if you had been
using the `params` property to access query parameters like this in 1.x:

```dart
GoRoute(
  path: '/login',
  pageBuilder: (context, state) => MaterialPage<void>(
    key: state.pageKey,
    // 1.x: accessing query parameters
    child: LoginPage(from: state.params['from']),
  ),
),
```

in 2.0, you would access the query parameters like this:

```dart
GoRoute(
  path: '/login',
  pageBuilder: (context, state) => MaterialPage<void>(
    key: state.pageKey,
    // 2.0: accessing query parameters
    child: LoginPage(from: state.queryParams['from']),
  ),
),
```

Likewise, if you were using named routes in 1.x, you may have been passing both
path and query parameters like so:

```dart
ListTile(
  title: Text(p.name),
  // 1.x: passing both path and query parameters
  onTap: () => context.goNamed(
    'person',
    // "extra" path params were query params
    {'fid': family.id, 'pid': p.id, 'qid': 'quid'},
  ),
),
```

Now you'll need to change your code to do the following in 2.0:

```dart
ListTile(
  title: Text(p.name),
  // 2.0: passing both path and query parameters
  onTap: () => context.goNamed(
    'person',
    params: {'fid': family.id, 'pid': p.id},
    queryParams: {'qid': 'quid'},
  ),
),
```

I got a little clever merging the two kinds of parameters into a single scope
and hopefully this change makes things a little more clear.

# Getting Started

To use the go_router package, [follow these
instructions](https://pub.dev/packages/go_router/install).

# Video Overview

If you'd like to see a video overview of the go_router package, you can watch
the following:

[![Flutter Navigator 2.0 made easy with
go_router](https://img.youtube.com/vi/G41NdhieUoc/0.jpg)](https://www.youtube.com/watch?v=G41NdhieUoc)

In this video, I did some pair programming with Majid Hajian to port an existing
Flutter app built using the original Navigation API to use go_router for both
mobile and web.

# Declarative Routing

The go_router is governed by a set of routes which you specify as part of the
`GoRouter` constructor:

```dart
class App extends StatelessWidget {
  ...
  final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: const Page1Page(),
        ),
      ),
      GoRoute(
        path: '/page2',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: const Page2Page(),
        ),
      ),
    ],
  ...
  );
}
```

In this case, we've defined two routes. Each route `path` will be matched
against the location to which the user is navigating. Only a single path will be
matched, specifically the one that matches the entire location (and so it
doesn't matter in which order you list your routes). The `path` will be matched
in a case-insensitive way, although the case for [parameters](#parameters) will
be preserved.

## Router state

A `GoRoute` also contains a `pageBuilder` function which is called to create the
page when a path is matched. The builder function is passed a `state` object,
which is an instance of the `GoRouterState` class that contains some useful
information:

| `GoRouterState` property | description                                        | example 1                | example 2                  |
| ------------------------ | -------------------------------------------------- | ------------------------ | -------------------------- |
| `location`               | location of the full route, including query params | `/login?from=/family/f2` | `/family/f2/person/p1`     |
| `subloc`                 | location of this sub-route w/o query params        | `/login`                 | `/family/f2`               |
| `name`                   | the `GoRoute` name                                 | `login`                  | `family`                   |
| `path`                   | the `GoRoute` path                                 | `/login`                 | `family/:fid`              |
| `fullpath`               | full path to this sub-route                        | `/login`                 | `/family/:fid`             |
| `params`                 | params extracted from the location                 | `{}`                     | `{'fid': 'f2'}`            |
| `queryParams`            | optional params from the end of the location       | `{'from': '/family/f1'}` | `{}`                       |
| `extra`                  | optional object param                              | `null`                   | `null`                     |
| `error`                  | `Exception` associated with this sub-route, if any | `Exception('404')`       | ...                        |
| `pageKey`                | unique key for this sub-route                      | `ValueKey('/login')`     | `ValueKey('/family/:fid')` |

You can read more about [sub-locations/sub-routes](#sub-routes) and
[parameterized routes](#parameters) below but the example code above uses the
`pageKey` property as most of the example code does. The `pageKey` is used to
create a unique key for the `MaterialPage` or `CupertinoPage` based on the
current path for that page in the [stack of pages](#sub-routes), so it will
uniquely identify the page w/o having to hardcode a key or come up with one
yourself.

Not all of the state parameters will be set every time. In general, the state is
a superset of the potential current state of a `GoRouter` instance. For example,
the `error` parameter will only be set of there's an error, the `params` won't
be set during top-level redirection because there's no `path` to match yet, etc.

## Error handling

In addition to the list of routes, the go_router needs an `errorPageBuilder`
function in case no page is found, more than one page is found or if any of the
page builder functions throws an exception, e.g.

```dart
class App extends StatelessWidget {
  ...
  final _router = GoRouter(
    ...
    errorPageBuilder: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      child: ErrorPage(state.error),
    ),
  );
}
```

The `GoRouterState` object contains the location that caused the exception and
the `Exception` that was thrown attempting to navigate to that route.

## Initialization

With just a list of routes and an error page builder function, you can create an
instance of a `GoRouter`, which itself provides the objects you need to call the
`MaterialApp.router` constructor:

```dart
class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
      );

  final _router = GoRouter(routes: ..., errorPageBuilder: ...);
}
```

With the router in place, your app can now navigate between pages.

# Navigation

To navigate between pages, use the `GoRouter.go` method:

```dart
// navigate using the GoRouter
onTap: () => GoRouter.of(context).go('/page2')
```

The go_router also provides a simplified means of navigation using Dart
extension methods:

```dart
// more easily navigate using the GoRouter
onTap: () => context.go('/page2')
```

The simplified version maps directly to the more fully-specified version, so you
can use either. If you're curious, the ability to just call `context.go(...)`
and have magic happen is where the name of the go_router came from.

If you'd like to navigate via [the `Link`
widget](https://pub.dev/documentation/url_launcher/latest/link/link-library.html),
that works, too:

```dart
Link(
  uri: Uri.parse('/page2'),
  builder: (context, followLink) => TextButton(
    onPressed: followLink,
    child: const Text('Go to page 2'),
  ),
),
```

If the `Link` widget is given a URL with a scheme, e.g. `https://flutter.dev`,
then it will launch the link in a browser. Otherwise, it'll navigate to the link
inside the app using the built-in navigation system.

You can also navigate to a [named route](#named-routes), discussed below.

## Current location

If you want to know the current location, use the `GoRouter.location` property.
If you'd like to know when the current location changes, either because of
manual navigation or a deep link or a pop due to the user pushing the Back
button, the `GoRouter` is a
[`ChangeNotifier`](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html),
which means that you can call `addListener` to be notified when the location
changes, either manually or via Flutter's builder widget for `ChangeNotifier`
objects, the non-intuitively named
[`AnimatedBuilder`](https://stackoverflow.com/a/67016227):

```dart
class RouterLocationView extends StatelessWidget {
  const RouterLocationView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    return AnimatedBuilder(
      animation: router,
      builder: (context, child) => Text(router.location),
    );
  }
}
```

Or, if you're using [the provider package](https://pub.dev/packages/provider),
it comes with built-in support for re-building a `Widget` when a
`ChangeNotifier` changes with a type that is much more clearly suited for the
purpose.

# Initial Location

If you'd like to set an initial location for routing, you can set the
`initialLocation` argument of the `GoRouter` constructor:

```dart
final _router = GoRouter(
  routes: ...,
  errorPageBuilder: ...,
  initialLocation: '/page2',
);
```

The value you provide to `initialLocation` will be ignored if your app is started
using [deep linking](#deep-linking).

# Parameters

The route paths are defined and implemented in [the path_to_regexp
package](https://pub.dev/packages/path_to_regexp), which gives you the ability
to include parameters in your route's `path`:

```dart
final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/family/:fid',
      pageBuilder: (context, state) {
        // use state.params to get router parameter values
        final family = Families.family(state.params['fid']!);

        return MaterialPage<void>(
          key: state.pageKey,
          child: FamilyPage(family: family),
        );
      },
    ),
  ],
  errorPageBuilder: ...,
]);
```

You can access the matched parameters in the `state` object using the `params`
property.

## Dynamic linking

The idea of "dynamic linking" is that as the user adds objects to your app, each
of them gets a link of their own, e.g. a new family gets a new link. This is
exactly what route parameters enables, e.g. a new family has its own identifier
when can be a variable in your family route, e.g. path: `/family/:fid`.

# Sub-routes

Every top-level route will create a navigation stack of one page. To produce an
entire stack of pages, you can use sub-routes. In the case that a top-level
route only matches part of the location, the rest of the location can be matched
against sub-routes. The rules are still the same, i.e. that only a single
route at any level will be matched and the entire location much be matched.

For example, the location `/family/f1/person/p2`, can be made to match multiple
sub-routes to create a stack of pages:

```text
/             => HomePage()
  family/f1   => FamilyPage('f1')
    person/p2 => PersonPage('f1', 'p2') ← showing this page, Back pops the stack ↑
```

To specify a set of pages like this, you can use sub-page routing via the
`routes` parameter to the `GoRoute` constructor:

```dart
final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => MaterialPage<void>(
        key: state.pageKey,
        child: HomePage(families: Families.data),
      ),
      routes: [
        GoRoute(
          path: 'family/:fid',
          pageBuilder: (context, state) {
            final family = Families.family(state.params['fid']!);

            return MaterialPage<void>(
              key: state.pageKey,
              child: FamilyPage(family: family),
            );
          },
          routes: [
            GoRoute(
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
  ],
  errorPageBuilder: ...
);
```

The go_router will match the routes all the way down the tree of sub-routes to
build up a stack of pages. If go_router doesn't find a match, then the error
handler will be called.

Also, the go_router will pass parameters from higher level sub-routes so that
they can be used in lower level routes, e.g. `fid` is matched as part of the
`family/:fid` route, but it's passed along to the `person/:pid` route because
it's a sub-route of the `family/:fid` route.

# Pushing pages

In addition to the `go` method, the go_router also provides a `push` method.
Both `go` and `push` can be used to build up a stack of pages, but in different
ways. The `go` method does this by turning a single location into any number of
pages in a stack using [Sub-routes](#sub-routes).

The `push` method is used to push a single page onto the stack of existing
pages, which means that you can build up the stack programmatically instead of
declaratively. When the `push` method matches an entire stack via sub-routes, it
will take the top-most page from the stack and push that page onto the stack.

You can also push a [named route](#named-routes), discussed below.

## Popping pages

If you'd like to pop a page from the stack, you can use the `pop` method. This
method simply calls `Navigator.pop`. For more information about the integration
considerations of using `Navigator` vs `GoRouter`, see [Navigator
Integration](#navigator-integration).

# Redirection

Sometimes you want your app to redirect to a different location. The go_router
allows you to do this at a top level for each new navigation event or at the
route level for a specific route.

## Top-level redirection

Sometimes you want to guard pages from being accessed when they shouldn't be,
e.g. when the user is not yet logged in. For example, assume you have a class
that tracks the user's login info:

```dart
class LoginInfo extends ChangeNotifier {
  var _userName = '';
  String get userName => _userName;
  bool get loggedIn => _userName.isNotEmpty;

  void login(String userName) {
    _userName = userName;
    notifyListeners();
  }

  void logout() {
    _userName = '';
    notifyListeners();
  }
}
```

You can use this info in the implementation of a `redirect` function that you
pass as to the `GoRouter` constructor:

```dart
class App extends StatelessWidget {
  final loginInfo = LoginInfo();
  ...
  late final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: HomePage(families: Families.data),
        ),
      ),
      ...,
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: const LoginPage(),
        ),
      ),
    ],

    errorPageBuilder: ...,

    // redirect to the login page if the user is not logged in
    redirect: (state) {
      final loggedIn = loginInfo.loggedIn;
      final goingToLogin = state.location == '/login';

      // the user is not logged in and not headed to /login, they need to login
      if (!loggedIn && !goingToLogin) return '/login';

      // the user is logged in and headed to /login, no need to login again
      if (loggedIn && goingToLogin) return '/';

      // no need to redirect at all
      return null;
    },
  );
}
```

In this code, if the user is not logged in and not going to the `/login`
path, we redirect to `/login`. Likewise, if the user _is_ logged in but going to
`/login`, we redirect to `/`. If there is no redirect, then we just return
`null`. The `redirect` function will be called again until `null` is returned to
enable [multiple redirects](#multiple-redirections).

To make it easy to access this info wherever it's need in the app, consider
using a state management option like
[provider](https://pub.dev/packages/provider) to put the login info into the
widget tree:

```dart
class App extends StatelessWidget {
  final loginInfo = LoginInfo();

  // add the login info into the tree as app state that can change over time
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<LoginInfo>.value(
        value: loginInfo,
        child: MaterialApp.router(...),
      );
  ...
}
```

With the login info in the widget tree, you can easily implement your login
page:

```dart
class LoginPage extends StatelessWidget {
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

              // go home
              context.go('/');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    ),
  );
}
```

In this case, we've logged the user in and manually redirected them to the home
page. That's because the go_router doesn't know that the app's state has
changed in a way that affects the route. If you'd like to have the app's state
cause go_router to automatically redirect, you can use the `refreshListenable`
argument of the `GoRouter` constructor:

```dart
class App extends StatelessWidget {
  final loginInfo = LoginInfo();
  ...
  late final _router = GoRouter(
    routes: ...,
    errorPageBuilder: ...,
    redirect: ...

    // changes on the listenable will cause the router to refresh it's route
    refreshListenable: loginInfo,
  );
}
```

Since the `loginInfo` is a `ChangeNotifier`, it will notify listeners when it
changes. By passing it to the `GoRouter` constructor, the go_router will
automatically refresh the route when the login info changes. This allows you to
simplify the login logic in your app:

```dart
onPressed: () {
  // log a user in, letting all the listeners know
  context.read<LoginInfo>().login('test-user');

  // router will automatically redirect from /login to / because login info
  //context.go('/');
},
```

The use of the top-level `redirect` and `refreshListenable` together is
recommended because it will handle the routing automatically for you when the
app's data changes.

## Route-level redirection

The top-level redirect handler passed to the `GoRouter` constructor is handy when you
want a single function to be called whenever there's a new navigation event and
to make some decisions based on the app's current state. However, in the case
that you'd like to make a redirection decision for a specific route (or
sub-route), you can do so by passing a `redirect` function to the `GoRoute`
constructor:

```dart
final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      redirect: (_) => '/family/${Families.data[0].id}',
    ),
    GoRoute(
      path: '/family/:fid',
      pageBuilder: ...,
  ],
  errorPageBuilder: ...,
);
```

In this case, when the user navigates to `/`, the `redirect` function will be
called to redirect to the first family's page. Redirection will only occur on
the last sub-route matched, so you can't have to worry about redirecting in the
middle of a location being parsed when you're already on your way to another
page anyway.

## Parameterized redirection

In some cases, a path is parameterized, and you'd like to redirect with those
parameters in mind. You can do that with the `params` argument to the `state`
object passed to the `redirect` function:

```dart
GoRoute(
  path: '/author/:authorId',
  redirect: (state) => '/authors/${state.params['authorId']}',
),
```

## Multiple redirections

It's possible to redirect multiple times w/ a single navigation, e.g. `/ => /foo => /bar`. This is handy because it allows you to build up a list of
routes over time and not to worry so much about attempting to trim each of them
to their direct route. Furthermore, it's possible to redirect at the top level
and at the route level in any number of combinations.

If you redirect too many times, that's likely to indicate a bug in your app. By
default, more than 5 redirections will cause an exception. You can change this
by setting the `redirectLimit` argument to the `GoRouter` constructor.

The other trouble you need worry about is getting into a loop, e.g. `/ => /foo => /`. If that happens, you'll get an exception.

# Query Parameters

Sometimes you're doing [deep linking](#deep-linking) and you'd like a user to
first login before going to the location that represents the deep link. In that
case, you can use query parameters in the redirect function:

```dart
class App extends StatelessWidget {
  final loginInfo = LoginInfo();
  ...
  late final _router = GoRouter(
    routes: ...,
    errorPageBuilder: ...,

    // redirect to the login page if the user is not logged in
    redirect: (state) {
      final loggedIn = loginInfo.loggedIn;

      // check just the subloc in case there are query parameters
      final goingToLogin = state.subloc == '/login';

      // the user is not logged in and not headed to /login, they need to login
      if (!loggedIn && !goingToLogin) return '/login?from=${state.subloc}';

      // the user is logged in and headed to /login, no need to login again
      if (loggedIn && goingToLogin) return '/';

      // no need to redirect at all
      return null;
    },

    // changes on the listenable will cause the router to refresh it's route
    refreshListenable: loginInfo,
  );
}
```

In this example, if the user isn't logged in, they're redirected to `/login`
with a `from` query parameter set to the deep link. The `state` object has the
`location` and the `subloc` to choose from. The `location` includes the query
parameters whereas the `subloc` does not. Since the `/login` route may include
query parameters, it's easiest to use the `subloc` in this case (and using the
raw `location` will cause a stack overflow, an exercise that I'll leave to the
reader).

Now, when the `/login` route is matched, we want to pull the `from` parameter
out of the `state` object to pass along to the `LoginPage`:

```dart
GoRoute(
  path: '/login',
  pageBuilder: (context, state) => MaterialPage<void>(
    key: state.pageKey,
    // pass the original location to the LoginPage (if there is one)
    child: LoginPage(from: state.queryParams['from']),
  ),
),
```

In the `LoginPage`, if the `from` parameter was passed, we use it to go to the
deep link location after a successful login:

```dart
class LoginPage extends StatelessWidget {
  final String? from;
  const LoginPage({this.from, Key? key}) : super(key: key);

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
```

It's still good practice to pass in the `refreshListenable` when manually
redirecting, as we do in this case, to ensure any change to the login info
causes the right routing to happen automatically, e.g. the user logging out will
cause them to be routed back to the login page.

# Extra parameter

In addition to passing along path and query parameters, you can also pass along
an extra object as part of your navigation, e.g.

```dart
void _tap(BuildContext context, Family family) =>
  context.go('/family', extra: family);
```

This object is available during the `pageBuilder` function as `state.extra`:

```dart
GoRoute(
  path: '/family',
  pageBuilder: (context, state) => MaterialPage<Family>(
    key: state.pageKey,
    child: FamilyPage(family: state.extra! as Family),
  ),
),
```

The `extra` object is useful if you'd like to simply pass along a single object
to the `pageBuilder` function w/o passing an object identifier via a URI and
looking up the object from a store. _However_, this object cannot be used to
create a dynamic link, cannot be used in deep linking and so is _not
recommended_ for those cases.

# Named Routes

When you're navigating to a route with a location, you're hardcoding the URI
construction into your app, e.g.

```dart
void _tap(BuildContext context, String fid, String pid) =>
  context.go('/family/$fid/person/$pid');
```

Not only is that error-prone, but the actual URI format of your app could change
over time. Certainly redirection helps keep old URI formats working, but do you
really want various versions of your location URIs lying around willy-nilly in
your code?

## Navigating to Named Routes

The idea of named routes is to make it easy to navigate to a route w/o knowing
or caring what the URI format is. You can add a unique name to your route using
the `GoRoute.name` parameter:

```dart
final _router = GoRouter(
  routes: [
    GoRoute(
      name: 'home',
      path: '/',
      pageBuilder: ...,
      routes: [
        GoRoute(
          name: 'family',
          path: 'family/:fid',
          pageBuilder: ...,
          routes: [
            GoRoute(
              name: 'person',
              path: 'person/:pid',
              pageBuilder: ...,
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      name: 'login',
      path: '/login',
      pageBuilder: ...,
    ),
  ],
```

You don't need to name any of your routes but the ones that you do name, you can
navigate to using the name and whatever params are needed:

```dart
void _tap(BuildContext context, String fid, String pid) =>
  context.go(context.namedLocation('person', params: {'fid': fid, 'pid': pid}));
```

The `namedLocation` method will look up the route by name in a case-insensitive
way, construct the URI for you and fill in the params as appropriate. If you
miss a param or pass in params that aren't part of the path, you'll get an
error. Since it's somewhat inconvenient to have to dereference the `context`
object twice, go_router provides a `goNamed` method that does the lookup and
navigation in one step:

```dart
void _tap(BuildContext context, String fid, String pid) =>
  context.goNamed('person', params: {'fid': fid, 'pid': pid});
```

There is also a `pushNamed` method that will look up the route by name, pull the
top page off of the generated match stack and push that onto the existing stack
of pages.

## Redirecting to Named Routes

In addition to navigation, you may also want to be able to redirect to a named
route, which you can also do using the `namedLocation` method of either
`GoRouter` or `GoRouterState`:

```dart
// redirect to the login page if the user is not logged in
redirect: (state) {
  final loggedIn = loginInfo.loggedIn;

  // check just the subloc in case there are query parameters
  final loginLoc = state.namedLocation('login');
  final goingToLogin = state.subloc == loginLoc;

  // the user is not logged in and not headed to /login, they need to login
  if (!loggedIn && !goingToLogin)
    return state.namedLocation('login', queryParams: {'from': state.subloc});

  // the user is logged in and headed to /login, no need to login again
  if (loggedIn && goingToLogin) return state.namedLocation('home');

  // no need to redirect at all
  return null;
},
```

In this example, we're using `namedLocation` to get the location for the named
'login' route and then comparing it to the current `subloc` to find out if the
user is currently logging in or not. Furthermore, when we construct a location
for redirection, we use `namedLocation` to pass in parameters to construct the
location. All of this is done without hardcoding any URI formatting into your
code.

# Custom Transitions

As you transition between routes, you get transitions based on whether
you're using `MaterialPage` or `CupertinoPage`; each of them implements the
transitions as defined by the underlying platform. However, if you'd like to
implement a custom transition, you can do so by using the `CustomTransitionPage`
provided with go_router:

```dart
GoRoute(
  path: '/fade',
  pageBuilder: (context, state) => CustomTransitionPage<void>(
    key: state.pageKey,
    child: const TransitionsPage(kind: 'fade', color: Colors.red),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  ),
),
```

The `transitionBuilder` argument to the `CustomTransitionPage` is called when
you're routing to a new route, and it's your chance to return a transition
widget. The [transitions
sample](https://github.com/csells/go_router/blob/master/example/lib/transitions.dart)
shows off four different kind of transitions, but really you can do whatever you
want.

![custom transitions example](https://raw.githubusercontent.com/csells/go_router/master/readme/transitions.gif)

The `CustomTransitionPage` constructor also takes a `transitionsDuration`
argument in case you'd like to customize the duration of the transition as well
(it defaults to 300ms).

# Async Data

Sometimes you'll want to load data asynchronously, and you'll need to wait for
the data before showing content. Flutter provides a way to do this with the
`FutureBuilder` widget that works just the same with the go_router as it always
does in Flutter. For example, imagine you've got a `Repository` class that does
network communication when it looks up data:

```dart
class Repository {
  Future<List<Family>> getFamilies() async { /* network comm */ }
  Future<Family> getFamily(String fid) async => { /* network comm */ }
  ...
}
```

Now you can use the `FutureBuilder` to show a loading indicator while the data
is loading:

```dart
class App extends StatelessWidget {
  final repo = Repository();
  ...
  late final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: FutureBuilder<List<Family>>(
            future: repo.getFamilies(),
            pageBuilder: (context, snapshot) {
              if (snapshot.hasError)
                return ErrorPage(snapshot.error as Exception?);
              if (snapshot.hasData) return HomePage(families: snapshot.data!);
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
        routes: [
          GoRoute(
            path: 'family/:fid',
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: FutureBuilder<Family>(
                future: repo.getFamily(state.params['fid']!),
                pageBuilder: (context, snapshot) {
                  if (snapshot.hasError)
                    return ErrorPage(snapshot.error as Exception?);
                  if (snapshot.hasData)
                    return FamilyPage(family: snapshot.data!);
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
            routes: [
              GoRoute(
                path: 'person/:pid',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: state.pageKey,
                  child: FutureBuilder<FamilyPerson>(
                    future: repo.getPerson(
                      state.params['fid']!,
                      state.params['pid']!,
                    ),
                    pageBuilder: (context, snapshot) {
                      if (snapshot.hasError)
                        return ErrorPage(snapshot.error as Exception?);
                      if (snapshot.hasData)
                        return PersonPage(
                            family: snapshot.data!.family,
                            person: snapshot.data!.person);
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      child: ErrorPage(state.error),
    ),
  );
}

class NoTransitionPage<T> extends CustomTransitionPage<T> {
  const NoTransitionPage({required Widget child, LocalKey? key})
      : super(transitionsBuilder: _transitionsBuilder, child: child, key: key);

  static Widget _transitionsBuilder(
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child) =>
      child;
}
```

This is a simple case that shows a circular progress indicator while the data is
being loaded and before the page is shown.

![async data example](https://raw.githubusercontent.com/csells/go_router/master/readme/async.gif)

The way transitions work, the outgoing page is shown for a little while before
the incoming page is shown, which looks pretty terrible when your page is doing
nothing but showing a circular progress indicator. I admit that I took the
coward's way out and turned off the transitions so that things wouldn't look
so bad in the animated screenshot. However, it would be nicer to keep the
transition, navigate to the page showing as much as possible, e.g. the `AppBar`,
and then show the loading indicator inside the page itself. In that case, you'll
be on your own to show an error in the case that the data can't be loaded. Such
polish is left as an exercise for the reader.

# Nested Navigation

Sometimes you want to choose a page based on a route as well as the state of
that page, e.g. the currently selected tab. In that case, you want to choose not
just the page from a route but also the widgets nested inside the page. That's
called "nested navigation". The key differentiator for "nested" navigation is
that there's no transition on the part of the page that stays the same, e.g. the
app bar stays the same as you navigate to different tabs on this `TabView`:

![nested navigation example](https://raw.githubusercontent.com/csells/go_router/master/readme/nested-nav.gif)

Of course, you can easily do this using the `TabView` widget, but what makes
this nested "navigation" is that the location of the page changes, i.e. notice
the address bar as the user transitions from tab to tab. This makes it easy for
the user to capture a [dynamic link](#deep-linking) for any object in the app,
enabling [deep linking](#deep-linking).

To use nested navigation using go_router, you can simply navigate to the same
page via different paths or to the same path with different parameters, with
the differences dictating the different state of the page. For example, to
implement that page with the `TabView` above, you need a widget that changes the
selected tab via a parameter:

```dart
class FamilyTabsPage extends StatefulWidget {
  final int index;
  FamilyTabsPage({required Family currentFamily, Key? key})
      : index = Families.data.indexWhere((f) => f.id == currentFamily.id),
        super(key: key) {
    assert(index != -1);
  }

  @override
  _FamilyTabsPageState createState() => _FamilyTabsPageState();
}

class _FamilyTabsPageState extends State<FamilyTabsPage>
    with TickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: Families.data.length,
      vsync: this,
      initialIndex: widget.index,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.index = widget.index;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(_title(context)),
          bottom: TabBar(
            controller: _controller,
            tabs: [for (final f in Families.data) Tab(text: f.name)],
            onTap: (index) => _tap(context, index),
          ),
        ),
        body: TabBarView(
          controller: _controller,
          children: [for (final f in Families.data) FamilyView(family: f)],
        ),
      );

  void _tap(BuildContext context, int index) =>
      context.go('/family/${Families.data[index].id}');

  String _title(BuildContext context) =>
      (context as Element).findAncestorWidgetOfExactType<MaterialApp>()!.title;
}
```

The `FamilyTabsPage` is a stateful widget that takes the currently selected
family as a parameter. It uses the index of that family in the list of families
to set the currently selected tab. However, instead of switching the currently
selected tab to whatever the user clicks on, it uses navigation to get to that
index instead. It's the use of navigation that changes the address in the
address bar. And, the way that the tab index is switched is via the call to
`didChangeDependencies`. Because the `FamilyTabsPage` is a stateful widget, the
widget itself can be changed but the state is kept. When that happens, the call
to `didChangeDependencies` will change the index of the `TabController` to match
the new navigation location.

To implement the navigation part of this example, we need a route that
translates the location into an instance of `FamilyTabsPage` parameterized with
the currently selected family:

```dart
final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      redirect: (_) => '/family/${Families.data[0].id}',
    ),
    GoRoute(
      path: '/family/:fid',
      pageBuilder: (context, state) {
        final fid = state.params['fid']!;
        final family = Families.data.firstWhere((f) => f.id == fid,
            orElse: () => throw Exception('family not found: $fid'));

        return MaterialPage<void>(
          key: state.pageKey,
          child: FamilyTabsPage(key: state.pageKey, currentFamily: family),
        );
      },
    ),
  ],

  errorPageBuilder: ...,
);
```

The `/` route is a redirect to the first family. The `/family/:fid` route is the
one that sets up nested navigation. It does this by first creating an
instance of `FamilyTabsPage` with the family that matches the `fid` parameter.
And second, it uses `state.pageKey` to signal to Flutter that this is the same
page as before. This combination is what causes the router to leave the page
alone, to update the browser's address bar and to let the `TabView` navigate to
the new selection.

This may seem like a lot, but in summary, you need to do three things with the
page you create in your page builder to support nested navigation:

1. Use a `StatefulWidget` as the base class of the thing you pass to
   `MaterialPage` (or whatever).

1. Pass the same key value to the `MaterialPage` so that Flutter knows that
   you're keeping the same state for your `StatefulWidget`-derived page;
   `state.pageKey` is handy for this.

1. As the user navigates, you'll create the same `StatefulWidget`-derived type,
   passing in new data, e.g. which tab is currently selected. Because you're
   using a widget with the same key, Flutter will keep the state but swap out the
   widget wrapping w/ the new data as constructor args. When that new widget wrapper is
   in place, Flutter will call `didChangeDependencies` so that you can use the new
   data to update the existing widgets, e.g. the selected tab.

This example shows off the selected tab on a `TabView` but you can use it for
any nested content of a page your app navigates to.

## Keeping State

When doing nested navigation, the user expects that widgets will be in the same
state that they left them in when they navigated to a new page and return, e.g.
scroll position, text input values, etc. You can enable support for this by
using `AutomaticKeepAliveClientMixin` on a stateful widget. You can see this in
action in the `FamiliyView` of the
[`nested_nav.dart`](https://github.com/csells/go_router/blob/master/example/lib/nested_nav.dart) example:

```dart
class FamilyView extends StatefulWidget {
  const FamilyView({required this.family, Key? key}) : super(key: key);
  final Family family;

  @override
  State<FamilyView> createState() => _FamilyViewState();
}

/// Use the [AutomaticKeepAliveClientMixin] to keep the state.
class _FamilyViewState extends State<FamilyView>
    with AutomaticKeepAliveClientMixin {

  // Override `wantKeepAlive` when using `AutomaticKeepAliveClientMixin`.
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    // Call `super.build` when using `AutomaticKeepAliveClientMixin`.
    super.build(context);
    return ListView(
      children: [
        for (final p in widget.family.people)
          ListTile(
            title: Text(p.name),
            onTap: () =>
                context.go('/family/${widget.family.id}/person/${p.id}'),
          ),
      ],
    );
  }
}
```

To instruct the `AutomaticKeepAliveClientMixin` to keep the state, you need to
override `wantKeepAlive` to return `true` and call `super.build` in the `State`
class's `build` method, as show above.

![keeping state example](https://raw.githubusercontent.com/csells/go_router/master/readme/keeping-state.gif)

Notice that after scrolling to the bottom of the long list of children in the
Hunting family, then going to another tab and then going to another page, when
you return to the list of Huntings that the scroll position is maintained.

# Navigator Builder

Sometimes it is necessary to insert a widget above the `Navigator`, but below
`MaterialApp`/`CupertinoApp`, e.g. to insert a provider that needs access to the
app's context to get the current locale and localization, to build a UI outside
of navigation or to completely replace with `Navigator` with something of your
own (which is outside the scope of this document).

For these purposes, you need to use the `navigatorBuilder` parameter in the
`GoRouter` constructor. This is similar to the `builder` parameter in the
`MaterialApp` constructor, but gives access to infrastructure provided by
`MaterialApp`.

An example of placing some data provider widget:

```dart
final _router = GoRouter(
  routes: ...,
  errorPageBuilder: ...,
  redirect: ...,
  refreshListenable: ...,

  // add a wrapper around the navigator to put loginInfo into the widget tree
  navigatorBuilder: (context, child) =>
      ChangeNotifierProvider<LoginInfo>.value(
    value: loginInfo,
    child: child,
    builder: (context, child) => child!,
  ),
);
```

A more interesting example of using `navigatorBuilder` is the following, which
puts a floating button on every page to allow for easy logout:

```dart
final _router = GoRouter(
  routes: ...,
  errorPageBuilder: ...,
  redirect: ...,
  refreshListenable: ...,

  // add a wrapper around the navigator to:
  // - put loginInfo into the widget tree, and to
  // - add an overlay to show a logout option
  navigatorBuilder: (context, child) =>
      ChangeNotifierProvider<LoginInfo>.value(
    value: loginInfo,
    child: child,
    builder: (context, child) => loginInfo.loggedIn
        ? AuthOverlay(onLogout: loginInfo.logout, child: child!)
        : child!,
  ),
);
```

This example checks the login status in the `navigatorBuilder`:

- if the user is logged in, an instance of the `AuthOverlay` widget is created,
  which wraps the the `Navigator` passed to `navigationBuilder` via the `child`
  parameter and provides a logout button on every page
- if the user is not logged in, return the `Navigator` via the `child` parameter

The `AuthOverlay` shows the logout button and the `Navigator` in a `Stack`:

```dart
class AuthOverlay extends StatelessWidget {
  const AuthOverlay({
    required this.onLogout,
    required this.child,
    Key? key,
  }) : super(key: key);

  final Widget child;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          child,
          Positioned(
            top: 90,
            right: 4,
            child: ElevatedButton(
              onPressed: onLogout,
              child: const Icon(Icons.logout),
            ),
          ),
        ],
      );
}
```

Here's what this look like in action:

![navigationBuilder in
action](https://raw.githubusercontent.com/csells/go_router/master/readme/nav_builder.gif)

# Deep Linking

Flutter defines "deep linking" as "opening a URL displays that screen in your
app." Anything that's listed as a `GoRoute` can be accessed via deep linking
across Android, iOS and the web. Support works out of the box for the web, of
course, via the address bar, but requires additional configuration for Android
and iOS as described in the [Flutter
docs](https://flutter.dev/docs/development/ui/navigation/deep-linking).

# URL Path Strategy

By default, Flutter adds a hash (#) into the URL for web apps:

![URL Strategy w/ Hash](https://raw.githubusercontent.com/csells/go_router/master/readme/url-strat-hash.png)

The process for turning off the hash is
[documented](https://flutter.dev/docs/development/ui/navigation/url-strategies)
but fiddly. The go_router has built-in support for setting the URL path
strategy, however, so you can simply call `GoRouter.setUrlPathStrategy` before
calling `runApp` and make your choice:

```dart
void main() {
  // turn on the # in the URLs on the web (default)
  // GoRouter.setUrlPathStrategy(UrlPathStrategy.hash);

  // turn off the # in the URLs on the web
  GoRouter.setUrlPathStrategy(UrlPathStrategy.path);

  runApp(App());
}
```

Setting the path instead of the hash strategy turns off the # in the URLs:

![URL Strategy w/o Hash](https://raw.githubusercontent.com/csells/go_router/master/readme/url-strat-no-hash.png)

If your router is created as part of the construction of the widget passed to
the `runApp` method, you can use a shortcut to set the URL path strategy by
using the `urlPathStrategy` parameter of the `GoRouter` constructor:

```dart
 // no need to call GoRouter.setUrlPathStrategy() here
 void main() => runApp(App());

/// sample app using the path URL strategy, i.e. no # in the URL path
class App extends StatelessWidget {
  ...
  final _router = GoRouter(
    routes: ...,
    errorPageBuilder: ...,

    // turn off the # in the URLs on the web
    urlPathStrategy: UrlPathStrategy.path,
  );
}
```

Finally, when you deploy your Flutter web app to a web server, it needs to be
configured such that every URL ends up at your Flutter web app's `index.html`,
otherwise Flutter won't be able to route to your pages. If you're using Firebase
hosting, you can [configure
rewrites](https://firebase.google.com/docs/hosting/full-config#rewrites) to
cause all URLs to be rewritten to `index.html`.

If you'd like to test your release build locally before publishing, and get that
cool redirect to `index.html` feature, you can use `flutter run` itself:

```sh
$ flutter run -d chrome --release lib/url_strategy.dart
```

Note that you have to run this command from a place where `flutter run` can find
the `web/index.html` file.

Of course, any local web server that can be configured to redirect all traffic
to `index.html` will do, e.g.
[live-server](https://www.npmjs.com/package/live-server).

# Debugging Your Routes

Because go_router asks that you provide a set of paths, sometimes as fragments
to match just part of a location, it's hard to know just what routes you have in
your app. In those cases, it's handy to be able to see the full paths of the
routes you've created as a debugging tool, e.g.

```text
GoRouter: known full paths for routes:
GoRouter:   => /
GoRouter:   =>   /family/:fid
GoRouter:   =>     /family/:fid/person/:pid
GoRouter: known full paths for route names:
GoRouter:   home => /
GoRouter:   family => /family/:fid
GoRouter:   person => /family/:fid/person/:pid
```

Likewise, there are multiple ways to navigate, e.g. `context.go()`,
`context.goNamed()`, `context.push()`, `context.pushNamed()`, the `Link` widget,
etc., as well as redirection, so it's handy to be able to see how that's going
under the covers, e.g.

```text
GoRouter: setting initial location /
GoRouter: location changed to /
GoRouter: getting location for name: "person", params: {fid: f2, pid: p1}
GoRouter: going to /family/f2/person/p1
GoRouter: location changed to /family/f2/person/p1
```

Finally, if there's an exception in your routing, you'll see that in the debug
output, too, e.g.

```text
GoRouter: Exception: no routes for location: /foobarquux
```

To enable this kind of output when your `GoRouter` is first created, you can use
the `debugLogDiagnostics` argument:

```dart
final _router = GoRouter(
  routes: ...,
  errorPageBuilder: ...,

  // log diagnostic info for your routes
  debugLogDiagnostics: true,
);
```

This parameter defaults to `false`, which produces no output.

# Navigator Integration

If you'd like to integrate with the built in `Navigator` widget, you can, as
shown in this snippet from the [navigator integration
example](https://github.com/csells/go_router/blob/master/example/lib/navigator_integration.dart):

```dart
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
```

This example shows how to use the `Navigator` widget to push a new page and
gather the result. It doesn't use the `GoRouter` but works just the way you'd
expect, e.g. it will create a new page on the stack of pages, show a Back button
in the `AppBar`, etc. To return results, use `Navigator.pop` as you normally
would:

```dart
ButtonBar(children: [
  TextButton(
    onPressed: () => Navigator.pop(context),
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
```

You can feel free to use `GoRouter` and `Navigator` together like this. However,
one thing that using `Navigator.push` in this way will not do is update the
browser's address bar. If you want that, you'll need to use `GoRouter.go` or
`GoRouter.push`. You'll notice, however, that neither `go` nor `push` provides
for waiting on results. That's because `GoRouter` is meant for use with deep and
dynamic linking, i.e. everything about a location in your app can be expressed
as a link. If you're calling `Navigator.push` and waiting on the results from
some random place in your app, that's not something that can be represented in a
link.

However, that doesn't mean that you can't use `GoRouter` to navigate to a page
that gathers user input; in fact, I expect that to happen all of the time.
Because the results of the navigation are not available to the caller when using
the `GoRouter`, the page itself would be responsible for managing what happens
to the user input, e.g.

```dart
ButtonBar(children: [
  TextButton(
    onPressed: () =>
      // Navigator.pop(context) would work here, too
      context.goNamed('family', params: {'fid': widget.family.id}),
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

        widget.family.people.add(person);

        context.goNamed('person', params: {
          'fid': widget.family.id,
          'pid': person.id,
        });
      }
    },
    child: const Text('Create'),
  ),
]),
```

With this implementation, you can set up a sub-route to provide a page to add a
new person:

```dart
GoRoute(
  name: 'home',
  path: '/',
  pageBuilder: ...,
  routes: [
    GoRoute(
      name: 'family',
      path: 'family/:fid',
      pageBuilder: ...,
      routes: [
        GoRoute(
          name: 'person',
          path: 'person/:pid',
          pageBuilder: ...,
        ),
        GoRoute(
          name: 'new-person',
          path: 'new-person',
          pageBuilder: (context, state) {
            final family = Families.family(state.params['fid']!);

            return MaterialPage<void>(
              key: state.pageKey,
              child: NewPersonPage(family: family),
            );
          },
        ),
      ],
    ),
  ],
),
```

And now your `_addPerson` method would look like this:

```dart
void _addPerson(BuildContext context) {
  context.goNamed('new-person', params: {'fid': widget.family.id});
}
```

And finally, when you're making changes to the data in your app that appears in
more than one place, e.g. updating the list of `Person` objects in a `Family` on
one page while also showing a list of those `Person` objects on another page,
you'll want to ensure that the widgets in your app can be rebuilt when the state
they depend on changes. For this, I recommend a state management solution like
[provider](https://pub.dev/packages/provider).

There's no reason not to use the `Navigator` in your app when you're using the
`GoRouter`, but you'll want to be careful how you manage your app's state and
the implications of using `Navigator` vs. `GoRouter` for navigation.

# Examples

You can see the go_router in action via the following examples:

- [`main.dart`](https://github.com/csells/go_router/blob/master/example/lib/main.dart):
  define a basic routing policy using a set of declarative `GoRoute` objects
- [`init_loc.dart`](https://github.com/csells/go_router/blob/master/example/lib/init_loc.dart):
  start at a specific location instead of home (`/`), which is the default
- [`sub_routes.dart`](https://github.com/csells/go_router/blob/master/example/lib/sub_routes.dart):
  provide a stack of pages based on a set of sub routes
- [`push.dart`](https://github.com/csells/go_router/blob/master/example/lib/push.dart):
  provide a stack of pages based on a series of calls to `context.push()`
- [`redirection.dart`](https://github.com/csells/go_router/blob/master/example/lib/redirection.dart):
  redirect one route to another based on changing app state
- [`query_params.dart`](https://github.com/csells/go_router/blob/master/example/lib/query_params.dart):
  optional query parameters will be passed to all page builders
- [`named_routes.dart`](https://github.com/csells/go_router/blob/master/example/lib/named_routes.dart):
  navigate via name instead of location URI
- [`transitions.dart`](https://github.com/csells/go_router/blob/master/example/lib/transitions.dart):
  use custom transitions during routing
- [`async_data.dart`](https://github.com/csells/go_router/blob/master/example/lib/async_data.dart):
  async data lookup
- [`nested_nav.dart`](https://github.com/csells/go_router/blob/master/example/lib/nested_nav.dart):
  include information about children on a page as part of the route path
- [`nav_builder.dart`](https://github.com/csells/go_router/blob/master/example/lib/nav_builder.dart):
  inject widgets above the `Navigator` widget
- [`url_strategy.dart`](https://github.com/csells/go_router/blob/master/example/lib/url_strategy.dart):
  turn off the # in the Flutter web URL
- [`navigator_integration.dart`](https://github.com/csells/go_router/blob/master/example/lib/navigator_integration.dart):
  using `Navigator` to navigate to a page that gathers user input
- [`state_restoration.dart`](https://github.com/csells/go_router/blob/master/example/lib/state_restoration.dart):
  test to ensure that go_router works with state restoration (it does)
- [`cupertino.dart`](https://github.com/csells/go_router/blob/master/example/lib/cupertino.dart):
  test to ensure that go_router works with the Cupertino design language as well
  as Material (it does)
- [`books/main.dart`](https://github.com/csells/go_router/blob/master/example/lib/books/main.dart):
  update of the
  [navigation_and_routing](https://github.com/flutter/samples/tree/master/navigation_and_routing)
  sample to use go_router

You can run these examples from the command line like so (from the `example`
folder):

```sh
$ flutter run lib/main.dart
```

Or, if you're using Visual Studio Code, a [`launch.json`](.vscode/launch.json)
file has been provided with these examples configured.

# Issues

Do you have an issue with or feature request for go_router? Log it on the [issue
tracker](https://github.com/csells/go_router/issues).
