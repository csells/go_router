// Copyright 2021, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../shared/pages.dart';
import 'auth.dart';
import 'data.dart';
import 'screens/author_details.dart';
import 'screens/book_details.dart';
import 'screens/scaffold.dart';
import 'screens/sign_in.dart';

class Bookstore extends StatelessWidget {
  final auth = BookstoreAuth();
  Bookstore({Key? key}) : super(key: key);

  late final _router = GoRouter(
    routes: _routes,
    error: _error,
    guard: Guard(auth),
    initialLocation: '/signin',
  );

  Iterable<GoRoute> _routes(BuildContext context, String location) => [
        // handle all of these...
        // /
        // /authors
        // /settings
        // /books/popular
        // /books/new
        // /books/all
        GoRoute(
          pattern: '/',
          builder: (context, state) => MaterialPage<BookstoreScaffold>(
            key: state.pageKey,
            child: const BookstoreScaffold(),
          ),
        ),

        GoRoute(
          pattern: '/book/:bookId',
          builder: (context, state) {
            final library = context.read<Library>();
            final bookId = int.tryParse(state.params['bookId'] ?? '') ?? -1;
            final book = library.findBook(bookId);

            return MaterialPage<BookDetailsScreen>(
              key: state.pageKey,
              child: BookDetailsScreen(book: book),
            );
          },
        ),

        GoRoute(
          pattern: '/author/:authorId',
          builder: (context, state) {
            final library = context.read<Library>();
            final authorId = int.tryParse(state.params['authorId'] ?? '') ?? -1;
            final author = library.findAuthor(authorId);

            return MaterialPage<void>(
              key: state.pageKey,
              child: AuthorDetailsScreen(author: author),
            );
          },
        ),

        GoRoute(
          pattern: '/signin',
          builder: (context, state) => MaterialPage<SignInScreen>(
            key: state.pageKey,
            child: const SignInScreen(),
          ),
        ),
      ];

  Page<dynamic> _error(BuildContext context, GoRouterState state) =>
      MaterialPage<ErrorPage>(
        key: state.pageKey,
        child: ErrorPage(state.error),
      );

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
        value: auth,
        child: Provider<Library>.value(
          value: Library.sample,
          child: MaterialApp.router(
            routerDelegate: _router.routerDelegate,
            routeInformationParser: _router.routeInformationParser,
          ),
        ),
      );
}

class Guard extends GoRouterGuard {
  final BookstoreAuth auth;

  // passing auth to the base class will cause a change to trigger routing
  Guard(this.auth) : super(auth);

  // redirect based on app and routing state
  @override
  String? redirect(String location) {
    final signedIn = auth.signedIn;
    const homeLoc = '/';
    const signInLoc = '/signin';

    // Go to /signin if the user is not signed in
    if (!signedIn && location != signInLoc) return signInLoc;

    // Go to / if the user is signed in and tries to go to /signin
    if (signedIn && location == signInLoc) return homeLoc;

    // otherwise, just go where they're going
    return null;
  }
}
