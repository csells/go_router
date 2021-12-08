// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

GoRoute get homeRoute => GoRouteData.$route(
      path: '/',
      factory: $HomeRouteExtension._fromState,
      routes: [
        GoRouteData.$route(
          path: 'family/:familyId',
          factory: $FamilyRouteExtension._fromState,
        ),
      ],
    );

extension $HomeRouteExtension on HomeRoute {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

  String get location => GoRouteData.$location(
        '/',
      );

  void go(BuildContext buildContext) => buildContext.go(location);
}

extension $FamilyRouteExtension on FamilyRoute {
  static FamilyRoute _fromState(GoRouterState state) => FamilyRoute(
        familyId: state.params['familyId']!,
      );

  String get location => GoRouteData.$location(
        '/family/${Uri.encodeComponent(familyId)}',
      );

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

  void go(BuildContext buildContext) =>
      buildContext.go(location, extra: $extra);
}
