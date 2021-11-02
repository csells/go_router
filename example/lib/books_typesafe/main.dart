// Copyright 2021, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';
import 'src/auth.dart';

void main() => runApp(Bookstore());

class Bookstore extends StatelessWidget {
  Bookstore({Key? key}) : super(key: key);

  final _scaffoldKey = const ValueKey<String>('App scaffold');

  @override
  Widget build(BuildContext context) => BookstoreAuthScope(
        notifier: _auth,
        child: MaterialApp.router(
          routerDelegate: _router.routerDelegate,
          routeInformationParser: _router.routeInformationParser,
        ),
      );

  final _auth = BookstoreAuth();

  late final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        redirect: (_) => BooksRoute().location,
      ),
      GoRoute(
        path: '/signin',
        pageBuilder: (context, state) =>
            SigninRoute().buildPage(context, state),
      ),
      GoRoute(
        path: '/books',
        redirect: (_) => BooksRoute(kind: 'popular').location,
      ),
      GoRoute(
        path: '/book/:bookId',
        redirect: (state) => BookDetailRoute.state(state).location,
      ),
      GoRoute(
        path: '/books/:kind(new|all|popular)',
        pageBuilder: (context, state) =>
            BooksRoute.state(state, key: _scaffoldKey)
                .buildPage(context, state),
        routes: [
          GoRoute(
            path: ':bookId',
            pageBuilder: (context, state) =>
                BookDetailRoute.state(state).buildPage(context, state),
          ),
        ],
      ),
      GoRoute(
        path: '/author/:authorId',
        redirect: (state) => '/authors/${state.params['authorId']}',
      ),
      GoRoute(
        path: '/authors',
        pageBuilder: (context, state) =>
            AuthorsRoute.state(state, key: _scaffoldKey)
                .buildPage(context, state),
        routes: [
          GoRoute(
            path: ':authorId',
            pageBuilder: (context, state) =>
                AuthorDetailRoute.state(state).buildPage(context, state),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            SettingsRoute.state(state, key: _scaffoldKey)
                .buildPage(context, state),
      ),
    ],
    errorPageBuilder: (context, state) =>
        ErrorRoute.state(state).buildPage(context, state),
    redirect: _guard,
    refreshListenable: _auth,
    debugLogDiagnostics: true,
  );

  String? _guard(GoRouterState state) {
    final signinRoute = SigninRoute();
    final booksRoute = BooksRoute();

    final signedIn = _auth.signedIn;
    final signingIn = state.subloc == signinRoute.location;

    // Go to /signin if the user is not signed in
    if (!signedIn && !signingIn) {
      return signinRoute.location;
    }
    // Go to /books if the user is signed in and tries to go to /signin.
    else if (signedIn && signingIn) {
      return booksRoute.location;
    }

    // no redirect
    return null;
  }
}
