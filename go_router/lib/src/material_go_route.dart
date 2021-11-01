// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import 'go_router_state.dart';

abstract class MaterialGoRoute<T> {
  MaterialPage<T> builder(BuildContext context, GoRouterState state) =>
      MaterialPage(key: state.pageKey, child: buildPage(context, state));

  Widget buildPage(BuildContext context, GoRouterState state);
}

class RouteDef {
  const RouteDef(
    this.name, {
    required this.path,
    this.parent,
  });

  final String name;
  final String path;
  final Type? parent;
}
