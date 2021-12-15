import 'package:go_router/go_router.dart';

part 'example.g.dart';

@RouteDef<HomeRoute>(
  path: '/',
  children: [
    RouteDef<FamilyRoute>(
      path: 'family/:familyId',
    )
  ],
)
class HomeRoute extends GoRouteData {
  const HomeRoute();

// implement build function
}

class FamilyRoute extends GoRouteData {
  const FamilyRoute({
    required this.familyId,
  });

  final String familyId;

// implement build function
}

@RouteDef<LoginRoute>(
  path: '/login',
)
class LoginRoute extends GoRouteData {
  const LoginRoute({
    this.from,
    this.$extra,
  });

  final String? from;
  final String? $extra;

// implement build function
}
