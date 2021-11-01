part of 'sample.dart';

extension HomeRouteExtension on HomeRoute {
  void go(BuildContext context) => context.goNamed('home');
}

extension FamilyRouteExtension on FamilyRoute {
  void go(BuildContext context) => context.goNamed(
        'family',
        params: {'fid': fid},
      );
}

extension PersonRouteExtension on PersonRoute {
  void go(BuildContext context) => context.goNamed(
        'person',
        params: {'fid': fid, 'pid': pid},
      );
}
