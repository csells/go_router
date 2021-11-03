part of 'named_routes.dart';

/// Generated name aligns with the element that's annotated.
/// Since [App] is annotated with [RouteDef] it becomes `appGoRoute`.
GoRoute get homeRoute => RouteData.$route(
      path: '/',
      factory: $HomeRouteExtension._fromState,
      routes: [
        RouteData.$route(
          path: 'family/:fid',
          factory: $FamilyRouteExtension._fromState,
          routes: [
            RouteData.$route(
                path: 'person/:pid',
                factory: $PersonRouteExtension._fromState,
                routes: [
                  RouteData.$route(
                    path: 'details/:details',
                    factory: $PersonDetailsRouteExtension._fromState,
                  )
                ])
          ],
        ),
      ],
    );

extension $HomeRouteExtension on HomeRoute {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

  String location({Map<String, String>? queryParams}) => RouteData.$location(
        '/',
        queryParams: queryParams,
      );

  /// This *could* be defined in [RouteData] – but only if [location] was not
  /// also an extension. Can't wait for macros!
  void go(
    BuildContext buildContext, {
    Map<String, String>? queryParams,
    Object? extra,
  }) {
    buildContext.go(location(queryParams: queryParams), extra: extra);
  }
}

extension $FamilyRouteExtension on FamilyRoute {
  static FamilyRoute _fromState(GoRouterState state) => FamilyRoute(
        state.params['fid']!,
      );

  String location({Map<String, String>? queryParams}) => RouteData.$location(
        '/family/${Uri.encodeComponent(fid)}',
        queryParams: queryParams,
      );

  /// This *could* be defined in [RouteData] – but only if [location] was not
  /// also an extension. Can't wait for macros!
  void go(
    BuildContext buildContext, {
    Map<String, String>? queryParams,
    Object? extra,
  }) {
    buildContext.go(location(queryParams: queryParams), extra: extra);
  }
}

extension $PersonRouteExtension on PersonRoute {
  static PersonRoute _fromState(GoRouterState state) => PersonRoute(
        state.params['fid']!,
        int.parse(state.params['pid']!),
      );

  String location({Map<String, String>? queryParams}) => RouteData.$location(
        '/family/${Uri.encodeComponent(fid)}'
        '/person/${Uri.encodeComponent(pid.toString())}',
        queryParams: queryParams,
      );

  /// This *could* be defined in [RouteData] – but only if [location] was not
  /// also an extension. Can't wait for macros!
  void go(
    BuildContext buildContext, {
    Map<String, String>? queryParams,
    Object? extra,
  }) {
    buildContext.go(location(queryParams: queryParams), extra: extra);
  }
}

extension $PersonDetailsRouteExtension on PersonDetailsRoute {
  static PersonDetailsRoute _fromState(GoRouterState state) =>
      PersonDetailsRoute(
        state.params['fid']!,
        int.parse(state.params['pid']!),
        PersonDetails.values.byName(state.params['details']!),
      );

  String location({Map<String, String>? queryParams}) => RouteData.$location(
        '/family/${Uri.encodeComponent(fid)}'
        '/person/${Uri.encodeComponent(pid.toString())}'
        '/details/${Uri.encodeComponent(details.name)}',
        queryParams: queryParams,
      );

  /// This *could* be defined in [RouteData] – but only if [location] was not
  /// also an extension. Can't wait for macros!
  void go(
    BuildContext buildContext, {
    Map<String, String>? queryParams,
    Object? extra,
  }) {
    buildContext.go(location(queryParams: queryParams), extra: extra);
  }
}

GoRoute get loginRoute => RouteData.$route(
      path: '/login',
      factory: $LoginRouteExtension._fromState,
    );

extension $LoginRouteExtension on LoginRoute {
  static LoginRoute _fromState(GoRouterState state) => LoginRoute(
        from: state.queryParams['from'],
      );

  String location({Map<String, String>? queryParams}) => RouteData.$location(
        '/login',
        queryParams: {
          ...?queryParams,
          // QUESTION: should user-provided query params "win" here?
          // Or should we throw an exception if there's a conflict?
          if (from != null) 'from': from!,
        },
      );

  /// This *could* be defined in [RouteData] – but only if [location] was not
  /// also an extension. Can't wait for macros!
  void go(
    BuildContext buildContext, {
    Map<String, String>? queryParams,
    Object? extra,
  }) {
    buildContext.go(location(queryParams: queryParams), extra: extra);
  }
}
