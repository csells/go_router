part of 'named_routes.dart';

/// Generated name aligns with the element that's annotated.
/// Since [App] is annotated with [RouteDef] it becomes `appGoRoute`.
GoRoute get homeRoute => GoRouteData.$route(
      path: '/',
      factory: $HomeRouteExtension._fromState,
      routes: [
        GoRouteData.$route(
          path: 'family/:fid',
          factory: $FamilyRouteExtension._fromState,
          routes: [
            GoRouteData.$route(
                path: 'person/:pid',
                factory: $PersonRouteExtension._fromState,
                routes: [
                  GoRouteData.$route(
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

  String get location => GoRouteData.$location('/');

  /// This *could* be defined in [GoRouteData] – but only if [location] was not
  /// also an extension. Can't wait for macros!
  void go(BuildContext buildContext) => buildContext.go(location);
}

extension $FamilyRouteExtension on FamilyRoute {
  static FamilyRoute _fromState(GoRouterState state) => FamilyRoute(
        state.params['fid']!,
      );

  String get location => GoRouteData.$location(
        '/family/${Uri.encodeComponent(fid)}',
      );

  /// This *could* be defined in [GoRouteData] – but only if [location] was not
  /// also an extension. Can't wait for macros!
  void go(BuildContext buildContext) => buildContext.go(location);
}

extension $PersonRouteExtension on PersonRoute {
  static PersonRoute _fromState(GoRouterState state) => PersonRoute(
        state.params['fid']!,
        int.parse(state.params['pid']!),
      );

  String get location => GoRouteData.$location(
        '/family/${Uri.encodeComponent(fid)}'
        '/person/${Uri.encodeComponent(pid.toString())}',
      );

  /// This *could* be defined in [GoRouteData] – but only if [location] was not
  /// also an extension. Can't wait for macros!
  void go(BuildContext buildContext) => buildContext.go(location);
}

extension $PersonDetailsRouteExtension on PersonDetailsRoute {
  static PersonDetailsRoute _fromState(GoRouterState state) =>
      PersonDetailsRoute(
        state.params['fid']!,
        int.parse(state.params['pid']!),
        _$PersonDetailsEnumMap.entries
            .singleWhere((element) => element.value == state.params['details']!)
            .key,
      );

  String get location => GoRouteData.$location(
        '/family/${Uri.encodeComponent(fid)}'
        '/person/${Uri.encodeComponent(pid.toString())}'
        '/details/${Uri.encodeComponent(_$PersonDetailsEnumMap[details]!)}',
      );

  /// This *could* be defined in [GoRouteData] – but only if [location] was not
  /// also an extension. Can't wait for macros!
  void go(BuildContext buildContext) => buildContext.go(location);
}

GoRoute get loginRoute => GoRouteData.$route(
      path: '/login',
      factory: $LoginRouteExtension._fromState,
    );

extension $LoginRouteExtension on LoginRoute {
  static LoginRoute _fromState(GoRouterState state) => LoginRoute(
        from: state.queryParams['from'],
        $extra: state.extra as String?,
      );

  String get location => GoRouteData.$location(
        '/login',
        queryParams: {
          if (from != null) 'from': from!,
        },
      );

  /// This *could* be defined in [GoRouteData] – but only if [location] was not
  /// also an extension. Can't wait for macros!
  void go(BuildContext buildContext) =>
      buildContext.go(location, extra: $extra);
}

const _$PersonDetailsEnumMap = {
  PersonDetails.hobbies: 'hobbies',
  PersonDetails.favoriteFood: 'favorite-food',
  PersonDetails.favoriteSport: 'favorite-sport',
};
