import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

part 'sample.g.dart';

@RouteDef('home', path: '/')
class HomeRoute extends MaterialGoRoute {
  @override
  Widget buildPage(BuildContext context, GoRouterState state) =>
      throw UnimplementedError();
}

// user defines a sub-route (under HomeRoute)
@RouteDef('family', path: 'family/:fid', parent: HomeRoute)
class FamilyRoute extends MaterialGoRoute {
  final String fid;
  FamilyRoute(this.fid);

  @override
  Widget buildPage(BuildContext context, GoRouterState state) =>
      throw UnimplementedError();
}

// user defines a sub-route (under FamilyRoute)
@RouteDef('person', path: 'person/:pid', parent: FamilyRoute)
class PersonRoute extends MaterialGoRoute {
  final String fid;
  final String pid;
  PersonRoute(this.fid, this.pid);

  @override
  Widget buildPage(BuildContext context, GoRouterState state) =>
      throw UnimplementedError();
}
