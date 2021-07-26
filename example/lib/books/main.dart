// Copyright 2021, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens.dart';

void main() => runApp(Bookstore());

class Bookstore extends StatelessWidget {
  Bookstore({Key? key}) : super(key: key);

  final router = GoRouter(
    routes: _routes,
    error: _error,
    initialLocation: '/books/popular',
  );

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routerDelegate: router.routerDelegate,
        routeInformationParser: router.routeInformationParser,
      );

  static Iterable<GoRoute> _routes(BuildContext context, String location) => [
        GoRoute(
          pattern: '/books/popular',
          builder: (context, state) => MaterialPage<void>(
            key: state.pageKey,
            child: const BooksScreen('popular'),
          ),
        ),
        GoRoute(
          pattern: '/books/new',
          builder: (context, state) => MaterialPage<void>(
            key: state.pageKey,
            child: const BooksScreen('new'),
          ),
        ),
        GoRoute(
          pattern: '/books/all',
          builder: (context, state) => MaterialPage<void>(
            key: state.pageKey,
            child: const BooksScreen('all'),
          ),
        ),
      ];

  static Page _error(BuildContext context, GoRouterState state) =>
      MaterialPage<void>(
        key: state.pageKey,
        child: ErrorScreen(state.error),
      );
}
