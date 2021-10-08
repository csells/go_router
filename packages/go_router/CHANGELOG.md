### 2.0.0
- BREAKING CHANGE and [Fix #50](https://github.com/csells/go_router/issues/50):
  split `params` into `params` and `queryParams`; see the [Migrating to 2.0
  section of the README](https://pub.dev/packages/go_router#migrating-to-20)
  for instructions on how to migrate your code from 1.x to 2.0
- [Fix 69](https://github.com/csells/go_router/issues/69): exposed named
  location lookup for redirection
- [Fix 57](https://github.com/csells/go_router/issues/57): enable the Android
  system Back button to behave exactly like the `AppBar` Back button; thanks to
  [SunlightBro](https://github.com/SunlightBro) for the one-line fix that I had
  no idea about until he pointed it out
- [Fix 59](https://github.com/csells/go_router/issues/59): add query params to
  top-level redirect
- [Fix 44](https://github.com/csells/go_router/issues/44): show how to use the
  `AutomaticKeepAliveClientMixin` with nested navigation to keep widget state
  between navigations; thanks to [rydmike](https://github.com/rydmike) for this
  update
- [Fix 61](https://github.com/csells/go_router/issues/61): hopefully fixing
  issues with relative file references on pub.dev/documentation (can't really
  know till I publish this version...)


### 1.1.3
- enable case-insensitive path matching while still preserving path and query
  parameter cases
- change a lifetime of habit to sort constructors first as per
  [sort_constructors_first](https://dart-lang.github.io/linter/lints/sort_constructors_first.html).
  Thanks for the PR, [Abhishek01039](https://github.com/Abhishek01039)!
- set the initial transition example route to `/none` to make pushing the 'fade
  transition' button on the first run through more fun
- fixed an error in the async data example


### 1.1.2
- Thanks, Mikes!
  - updated dartdocs from [rydmike](https://github.com/rydmike)
  - also shoutout to [https://github.com/Salakar](https://github.com/Salakar)
    for the CI action on GitHub
  - this is turning into a real community effort...


### 1.1.1
- now showing routing exceptions in the debug log
- updated the README to make it clear that it will be called until it returns
  `null`


### 1.1.0
- added support `NavigatorObserver` objects to receive change notifications


### 1.0.1
- README updates based on user feedback for clarity
- FIX: setting URL path strategy in `main()`
- FIX: `push()` disables `AppBar` Back button


### 1.0.0
- updated version for initial release
- some renaming for clarify and consistency with transitions
  - `GoRoute.builder` => `GoRoute.pageBuilder`
  - `GoRoute.error` => `GoRoute.errorPageBuilder`
- added diagnostic logging for `push` and `pushNamed`


### 0.9.6
- added support for `push` as well as `go`
- added 'none' to transitions example app
- updated animation example to use no transition and added an animated gif to
  the README


### 0.9.5
- added support for custom transitions between routes


### 0.9.4
- updated API docs
- updated README for `GoRouterState`


### 0.9.3
- updated API docs


### 0.9.2
- updated named route lookup to O(1)
- updated diagnostics output to show known named routes


### 0.9.1
- updated diagnostics output to show named route lookup
- README updates


### 0.9.0
- added support for named routes


### 0.8.8
- FIX: made `GoRouter` notify on pop


### 0.8.7
- made `GoRouter` a `ChangeNotifier` so you can listen for `location` changes


### 0.8.6
- books sample bug fix


### 0.8.5
- added Cupertino sample
- added example of async data lookup


### 0.8.4
- added state restoration sample


### 0.8.3
- Changed `debugOutputFullPaths` to `debugLogDiagnostics` and added add'l
  debugging logging
- parameterized redirect


### 0.8.2
- updated README for `Link` widget support


### 0.8.1
- added Books sample; fixed some issues it revealed


### 0.8.0
- breaking build to refactor the API for simplicity and capability
- move to fixed routing from conditional routing; simplies API, allows for
  redirection at the route level and there scenario was sketchy anyway
- add redirection at the route level
- replace guard objects w/ redirect functions
- add `refresh` method and `refreshListener`
- removed `.builder` ctor from `GoRouter` (not reasonable to implement)
- add Dynamic linking section to the README
- replaced Books sample with Nested Navigation sample
- add ability to dump the known full paths to your routes to debug output


### 0.7.1
- update to pageKey to take sub-routes into account


### 0.7.0
- BREAK: rename `pattern` to `path` for consistency w/ other routers in the
  world
- added the `GoRouterLoginGuard` for the common redirect-to-login-page pattern


### 0.6.2
- fixed issue showing home page for a second before redirecting (if needed)


### 0.6.1
- added `GoRouterState.pageKey`
- removed `cupertino_icons` from main `pubspec.yaml`


### 0.6.0
- refactor to support sub-routes to build a stack of pages instead of matching
  multiple routes
- added unit tests for building the stack of pages
- some renaming of the types, e.g. `Four04Page` and `FamiliesPage` to
  `ErrorPage` and `HomePage` respectively
- fix a redirection error shown in the debug output


### 0.5.2
- add `urlPathStrategy` argument to `GoRouter` ctor


### 0.5.1
- README and description updates


### 0.5.0
- moved redirect to top-level instead of per route for simplicity


### 0.4.1
- fixed CHANGELOG formatting


### 0.4.0
- bundled various useful route handling variables into the `GoRouterState` for
  use when building pages and error pages
- updated URL Strategy section of README to reference `flutter run`


### 0.3.2
- formatting update to appease the pub.dev gods...


### 0.3.1
- updated the CHANGELOG


### 0.3.0
- moved redirection into a `GoRoute` ctor arg
- forgot to update the CHANGELOG


### 0.2.3
- move outstanding issues to [issue
  tracker](https://github.com/csells/go_router/issues)
- added explanation of Deep Linking to README
- reformatting to meet pub.dev scoring guidelines


### 0.2.2
- README updates


### 0.2.1
- messing with the CHANGELOG formatting


### 0.2.0
- initial useful release
- added support for declarative routes via `GoRoute` instances
- added support for imperative routing via `GoRoute.builder`
- added support for setting the URL path strategy
- added support for conditional routing
- added support for redirection
- added support for optional query parameters as well as positional parameters
  in route names


### 0.1.0
- squatting on the package name (I'm not too proud to admit it)
