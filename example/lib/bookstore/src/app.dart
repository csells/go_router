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
  Bookstore({Key? key}) : super(key: key);

  late final _router = GoRouter(
    routes: _routes,
    error: _error,
    redirect: _redirect,
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
          builder: (context, state) => const MaterialPage<BookstoreScaffold>(
            key: ValueKey('App scaffold'),
            child: BookstoreScaffold(),
          ),
        ),

        GoRoute(
          pattern: '/book/:bookId',
          builder: (context, state) {
            final library = context.read<Library>();
            final bookId = int.tryParse(state.params['bookId'] ?? '') ?? -1;
            final book = library.findBook(bookId);

            return MaterialPage<BookDetailsScreen>(
              key: const ValueKey<String>('Book details screen'),
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
              key: const ValueKey<String>('Author details screen'),
              child: AuthorDetailsScreen(author: author),
            );
          },
        ),

        GoRoute(
          pattern: '/signin',
          builder: (context, state) => const MaterialPage<SignInScreen>(
            key: ValueKey('SignInScreen'),
            child: SignInScreen(),
          ),
        ),
      ];

  Page<dynamic> _error(BuildContext context, GoRouterState state) =>
      MaterialPage<ErrorPage>(
        child: ErrorPage(
          key: const ValueKey('ErrorPage'),
          message: state.error.toString(),
        ),
      );

  String? _redirect(BuildContext context, String location) {
    final auth = context.watch<BookstoreAuth>();
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

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => BookstoreAuth(),
        child: Provider<Library>.value(
          value: Library.sample,
          child: MaterialApp.router(
            routerDelegate: _router.routerDelegate,
            routeInformationParser: _router.routeInformationParser,
          ),
        ),
      );
}
