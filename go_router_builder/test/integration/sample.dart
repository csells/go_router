@RouteDef<HomeRoute>(
  path: '/',
  children: [
    RouteDef<FamilyRoute>(
      path: 'family/:fid',
      children: [
        RouteDef<PersonRoute>(
          path: 'person/:pid',
        ),
      ],
    )
  ],
)
library sample;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'sample.g.dart';

class HomeRoute extends RouteData {
  @override
  Widget build(BuildContext context) => throw UnimplementedError();
}

class FamilyRoute extends RouteData {
  final String fid;
  FamilyRoute(this.fid);

  @override
  Widget build(BuildContext context) => throw UnimplementedError();
}

class PersonRoute extends RouteData {
  final String fid;
  final String pid;
  PersonRoute(this.fid, this.pid);

  @override
  Widget build(BuildContext context) => throw UnimplementedError();
}
