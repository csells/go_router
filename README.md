<!-- hopefully a fix for https://github.com/csells/go_router/issues/61 -->
<head>
<base href="https://github.com/csells/go_router/" />
</head>

# go_router
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
number of routing and navigation policies at the cost of
[complexity](https://www.reddit.com/r/FlutterDev/comments/koxx4w/why_navigator_20_sucks/).

The purpose of the go_router is to use declarative routes to reduce complexity,
regardless of the platform you're targeting (mobile, web, desktop), handling
deep linking from Android, iOS and the web while still allowing an easy-to-use
developer experience.

# Table of Contents
- [Getting Started](#getting-started)
- [Declarative Routing](#declarative-routing)
  * [Router state](#router-state)
  * [Error handling](#error-handling)
  * [Initialization](#initialization)
- [Navigation](#navigation)
  * [Current location](#current-location)
- [Initial Location](#initial-location)
- [Parameters](#parameters)
  * [Dynamic linking](#dynamic-linking)
- [Sub-routes](#sub-routes)
- [Pushing pages](#pushing-pages)
- [Redirection](#redirection)
  * [Top-level redirection](#top-level-redirection)
  * [Route-level redirection](#route-level-redirection)
  * [Parameterized redirection](#parameterized-redirection)
  * [Multiple redirections](#multiple-redirections)
- [Query Parameters](#query-parameters)
- [Named Routes](#named-routes)
- [Custom Transitions](#custom-transitions)
- [Async Data](#async-data)
- [Nested Navigation](#nested-navigation)
  * [Keeping State](#keeping-state)
- [Deep Linking](#deep-linking)
- [URL Path Strategy](#url-path-strategy)
- [Debugging Your Routes](#debugging-your-routes)
- [Examples](#examples)
- [Issues](#issues)

# Getting Started
To use the go_router package, [follow these
instructions](https://pub.dev/packages/go_router/install).

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

| `GoRouterState` property | description | example 1 | example 2 |
| ------------------------ | ----------- | ------- | ------- |
| `location` | location of the full route, including query params | `/login?from=/family/f2` | `/family/f2/person/p1`|
| `subloc` | location of this sub-route w/o query params | `/login` | `/family/f2` |
| `path` | the `GoRoute` path | `/login` | `family/:fid` |
| `fullpath` | full path to this sub-route | `/login` | `/family/:fid` |
| `params` | params extracted from the location | `{'from': '/family/f1'}` | `{'fid': 'f2'}` |
| `error` | `Exception` associated with this sub-route, if any | `Exception('404')` | ... |
| `pageKey` | unique key for this sub-route | `ValueKey('/login')` | `ValueKey('/family/:fid')` |

You can read more about [sub-locations/sub-routes](#sub-routes) and [parametized
routes](#parameters) below but the example code above uses the `pageKey`
property as most of the example code does. The `pageKey` is used to create a
unique key for the `MaterialPage` or `CupertinoPage` based on the current path
for that page in the [stack of pages](#sub-routes), so it will uniquely identify
the page w/o having to hardcode a key or come up with one yourself.

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
path, we redirect to `/login`. Likewise, if the user *is* logged in but going to
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
It's possible to redirect multiple times w/ a single navigation, e.g. ```/ =>
/foo => /bar```. This is handy because it allows you to build up a list of
routes over time and not to worry so much about attempting to trim each of them
to their direct route. Furthermore, it's possible to redirect at the top level
and at the route level in any number of combinations.

The only trouble you need worry about is getting into a loop, e.g. ```/ => /foo
=> /```. If that happens, you'll get an exception with a message like this:
```Exception: Redirect loop detected: / => /foo => /```.

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

      // check just the path in case there are query parameters
      final goingToLogin = state.subloc == '/login';

      // the user is not logged in and not headed to /login, they need to login
      if (!loggedIn && !goingToLogin) return '/login?from=${state.location}';

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
    child: LoginPage(from: state.params['from']),
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

# Named Routes
When you're navigating to a route with a location, you're hardcoding the URI
construction into your app, e.g.

```dart
void _tap(BuildContext context, String fid, String pid) =>
  context.go('/family/$fid/person/$pid');
```

Not only is that error-prone, but the actual URI format of your app could change
over time. Certainly redirection helps keep old URI formats working, but do you
really want various versions of your location URIs lying willy-nilly around in
your code? The idea of named routes is to make it easy to navigate to a route
w/o knowing or caring what the URI format is. You can add a unique name to your
route using the `GoRoute.name` parameter:

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
  context.goNamed('person', {'fid': fid, 'pid': pid});
```

The `goNamed` method will look up the route by name in a case-insensitive way,
construct the URI for you and fill in the params as appropriate. If you miss a
param, you'll get an error. If you pass any extra params, they'll be passed as
query parameters.

There is also a `pushNamed` method that will look up the route by name, pull
the top page off of the stack and push that onto the existing stack of pages.

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
widget. The [transitions sample](example/lib/transitions.dart) shows off
four different kind of transitions, but really you can do whatever you want.

![custom transitions example](readme/transitions.gif)

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

![async data example](readme/async.gif)

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

![nested navigation example](readme/nested-nav.gif)

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
[`nested_nav.dart`](example/lib/nested_nav.dart) example:

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

![keeping state example](readme/keeping-state.gif)

Notice that after scrolling to the bottom of the long list of children in the
Hunting family, then going to another tab and then going to another page, when
you return to the list of Huntings that the scroll position is maintained.

# Deep Linking
Flutter defines "deep linking" as "opening a URL displays that screen in your
app." Anything that's listed as a `GoRoute` can be accessed via deep linking
across Android, iOS and the web. Support works out of the box for the web, of
course, via the address bar, but requires additional configuration for Android
and iOS as described in the [Flutter
docs](https://flutter.dev/docs/development/ui/navigation/deep-linking).

# URL Path Strategy
By default, Flutter adds a hash (#) into the URL for web apps:

![URL Strategy w/ Hash](readme/url-strat-hash.png)

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

![URL Strategy w/o Hash](readme/url-strat-no-hash.png)

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
GoRouter: looking up named route "person" with {fid: f2, pid: p1}
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

# Examples
You can see the go_router in action via the following examples:
- [`main.dart`](example/lib/main.dart): define a basic routing policy using a
  set of declarative `GoRoute` objects
- [`init_loc.dart`](example/lib/init_loc.dart): start at a specific location
  instead of home (`/`), which is the default
- [`sub_routes.dart`](example/lib/sub_routes.dart): provide a stack of pages
  based on a set of sub routes
- [`push.dart`](example/lib/push.dart): provide a stack of pages
  based on a series of calls to `context.push()`
- [`redirection.dart`](example/lib/redirection.dart): redirect one route to
  another based on changing app state
- [`query_params.dart`](example/lib/query_params.dart): optional query
  parameters will be passed to all page builders
- [`named_routes.dart`](example/lib/named_routes.dart): navigate via name
  instead of location URI
- [`transitions.dart`](example/lib/transitions.dart): use custom transitions
  during routing
- [`async_data.dart`](example/lib/async_data.dart): async data lookup
- [`nested_nav.dart`](example/lib/nested_nav.dart): include information about
  children on a page as part of the route path
- [`url_strategy.dart`](example/lib/url_strategy.dart): turn off the # in the
  Flutter web URL
- [`state_restoration.dart`](example/lib/state_restoration.dart): test to ensure
  that go_router works with state restoration (it does)
- [`cupertino.dart`](example/lib/cupertino.dart): test to ensure that go_router
  works with the Cupertino design language as well as Material (it does)
- [`books/main.dart`](example/lib/books/main.dart): update of the
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
