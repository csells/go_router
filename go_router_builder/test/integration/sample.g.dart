part of 'sample.dart';

GoRoute get homeGoRoute => GoRoute(
      path: '/',
      pageBuilder: $materialPageFactory(_$PathDataToHomeRoute),
      routes: [
        GoRoute(
          path: 'family/:fid',
          pageBuilder: $materialPageFactory(_$PathDataToFamilyRoute),
          routes: [
            GoRoute(
              path: 'person/:pid',
              pageBuilder: $materialPageFactory(_$PathDataToPersonRoute),
            )
          ],
        ),
      ],
    );

extension HomeRouteExtension on HomeRoute {
  String location(BuildContext buildContext) =>
      _$PathDataFromHomeRoute(this).namedLocation(buildContext);

  void go(BuildContext buildContext, {Object? extra}) {
    buildContext.go(location(buildContext), extra: extra);
  }
}

$PathData _$PathDataFromHomeRoute(HomeRoute value) => $PathData('/');

HomeRoute _$PathDataToHomeRoute(GoRouterState state) => HomeRoute();

extension FamilyRouteExtension on FamilyRoute {
  String location(BuildContext buildContext) =>
      _$PathDataFromFamilyRoute(this).namedLocation(buildContext);

  void go(BuildContext buildContext, {Object? extra}) {
    buildContext.go(location(buildContext), extra: extra);
  }
}

$PathData _$PathDataFromFamilyRoute(FamilyRoute value) =>
    $PathData('family', params: {'fid': value.fid});

FamilyRoute _$PathDataToFamilyRoute(GoRouterState state) => FamilyRoute(
      state.params['fid']!,
    );

extension PersonRouteExtension on PersonRoute {
  String location(BuildContext buildContext) =>
      _$PathDataFromPersonRoute(this).namedLocation(buildContext);

  void go(BuildContext buildContext, {Object? extra}) {
    buildContext.go(location(buildContext), extra: extra);
  }
}

$PathData _$PathDataFromPersonRoute(PersonRoute value) => $PathData(
      'family',
      params: {'fid': value.fid},
    );

PersonRoute _$PathDataToPersonRoute(GoRouterState state) => PersonRoute(
      state.params['fid']!,
      state.params['pid']!,
    );
