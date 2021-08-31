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
