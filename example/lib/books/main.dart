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
    routes: [
      GoRoute(
        path: '/',
        redirect: (location) => '/books/popular',
      ),
      GoRoute(
        path: '/books/:kind(popular|new|all)',
        builder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: BooksScreen(state.params['kind']!),
        ),
      ),
    ],
    errorBuilder: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      child: ErrorScreen(state.error),
    ),
  );

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routerDelegate: router.routerDelegate,
        routeInformationParser: router.routeInformationParser,
      );
}
