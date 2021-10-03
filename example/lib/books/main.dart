// Copyright 2021, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'src/auth.dart';
import 'src/data/library.dart';
import 'src/screens/author_details.dart';
import 'src/screens/authors.dart';
import 'src/screens/book_details.dart';
import 'src/screens/books.dart';
import 'src/screens/error.dart';
import 'src/screens/scaffold.dart';
import 'src/screens/settings.dart';
import 'src/screens/sign_in.dart';

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
  final _curveTween = CurveTween(curve: Curves.easeIn);

  late final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        redirect: (_) => '/books',
      ),
      GoRoute(
        path: '/signin',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(
                  opacity: animation.drive(_curveTween), child: child),
          child: SignInScreen(
            onSignIn: (credentials) {
              BookstoreAuthScope.of(context)
                  .signIn(credentials.username, credentials.password);
            },
          ),
        ),
      ),
      GoRoute(
        path: '/books',
        redirect: (_) => '/books/popular',
      ),
      GoRoute(
        path: '/book/:bookId',
        redirect: (state) => '/books/all/${state.params['bookId']}',
      ),
      GoRoute(
        path: '/books/:kind(new|all|popular)',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: _scaffoldKey,
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(
                  opacity: animation.drive(_curveTween), child: child),
          child: BookstoreScaffold(
            selectedTab: ScaffoldTab.books,
            child: BooksScreen(state.params['kind']!),
          ),
        ),
        routes: [
          GoRoute(
            path: ':bookId',
            pageBuilder: (context, state) {
              final bookId = state.params['bookId']!;
              final selectedBook = libraryInstance.allBooks
                  .firstWhereOrNull((b) => b.id.toString() == bookId);

              return MaterialPage<void>(
                key: state.pageKey,
                child: BookDetailsScreen(book: selectedBook),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/author/:authorId',
        redirect: (state) => '/authors/${state.params['authorId']}',
      ),
      GoRoute(
        path: '/authors',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: _scaffoldKey,
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(
                  opacity: animation.drive(_curveTween), child: child),
          child: const BookstoreScaffold(
            selectedTab: ScaffoldTab.authors,
            child: AuthorsScreen(),
          ),
        ),
        routes: [
          GoRoute(
            path: ':authorId',
            pageBuilder: (context, state) {
              final authorId = state.params['authorId']!;
              final selectedAuthor = libraryInstance.allAuthors
                  .firstWhereOrNull((a) => a.id.toString() == authorId);

              return MaterialPage<void>(
                key: state.pageKey,
                child: AuthorDetailsScreen(author: selectedAuthor),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: _scaffoldKey,
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(
                  opacity: animation.drive(_curveTween), child: child),
          child: const BookstoreScaffold(
            selectedTab: ScaffoldTab.settings,
            child: SettingsScreen(),
          ),
        ),
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      child: ErrorScreen(state.error),
    ),
    redirect: _guard,
    refreshListenable: _auth,
    debugLogDiagnostics: true,
  );

  String? _guard(GoRouterState state) {
    final signedIn = _auth.signedIn;
    final signingIn = state.subloc == '/signin';

    // Go to /signin if the user is not signed in
    if (!signedIn && !signingIn) {
      return '/signin';
    }
    // Go to /books if the user is signed in and tries to go to /signin.
    else if (signedIn && signingIn) {
      return '/books';
    }

    // no redirect
    return null;
  }
}
