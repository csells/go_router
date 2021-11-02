import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'src/auth.dart';
import 'src/data.dart';
import 'src/screens/author_details.dart';
import 'src/screens/authors.dart';
import 'src/screens/book_details.dart';
import 'src/screens/books.dart';
import 'src/screens/error.dart';
import 'src/screens/scaffold.dart';
import 'src/screens/settings.dart';
import 'src/screens/sign_in.dart';

//-----------BASE CLASSES-----------
abstract class TypedGoRoute {
  TypedGoRoute({
    required this.fullscreenDialog,
    required this.maintainState,
    required this.key,
    required this.name,
    required this.arguments,
    required this.restorationId,
  });

  final bool fullscreenDialog;
  final bool maintainState;
  final LocalKey? key;
  final String? name;
  final Object? arguments;
  final String? restorationId;

  // will mostly be implemented in the subclasses, e.g. MaterialGoRoute
  Page<dynamic> buildPage(BuildContext context, GoRouterState state);

  // will most be implemented in the page-specific subclasses, e.g. HomeRoute
  Widget build(BuildContext context);
}

abstract class MaterialGoRoute extends TypedGoRoute {
  MaterialGoRoute({
    String? name,
    bool maintainState = true,
    bool fullscreenDialog = false,
    LocalKey? key,
    Object? arguments,
    String? restorationId,
  }) : super(
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
          key: key,
          name: name,
          arguments: arguments,
          restorationId: restorationId,
        );

  @override
  Page<dynamic> buildPage(BuildContext context, GoRouterState state) =>
      MaterialPage<void>(
        key: key ?? state.pageKey,
        child: build(context),
      );
}

abstract class CustomTransitionGoRoute extends TypedGoRoute {
  CustomTransitionGoRoute({
    this.transitionDuration = const Duration(milliseconds: 300),
    this.opaque = true,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    bool maintainState = true,
    bool fullscreenDialog = false,
    LocalKey? key,
    String? name,
    Object? arguments,
    String? restorationId,
  }) : super(
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
          key: key,
          name: name,
          arguments: arguments,
          restorationId: restorationId,
        );

  final Duration transitionDuration;
  final bool opaque;
  final bool barrierDismissible;
  final Color? barrierColor;
  final String? barrierLabel;

  @override
  Page<dynamic> buildPage(BuildContext context, GoRouterState state) =>
      CustomTransitionPage<void>(
        child: build(context),
        transitionsBuilder: buildTransition,
        transitionDuration: transitionDuration,
        opaque: opaque,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        barrierLabel: barrierLabel,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
        key: key ?? state.pageKey,
        name: name,
        arguments: arguments,
        restorationId: restorationId,
      );

  Widget buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  );
}

//-----------USER CODE--------------
abstract class FadeTransitionRoute extends CustomTransitionGoRoute {
  FadeTransitionRoute({LocalKey? key}) : super(key: key);

  @override
  Widget buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      FadeTransition(
        opacity: animation.drive(CurveTween(curve: Curves.easeIn)),
        child: child,
      );
}

class HomeRoute extends FadeTransitionRoute {
  final String location = '/';
  void go(BuildContext context) => context.go(location);

  @override
  Widget build(BuildContext context) => throw UnimplementedError();
}

class SigninRoute extends FadeTransitionRoute {
  @override
  Widget build(BuildContext context) => SignInScreen(
        onSignIn: (credentials) {
          BookstoreAuthScope.of(context)
              .signIn(credentials.username, credentials.password);
        },
      );
}

class BooksRoute extends FadeTransitionRoute {
  BooksRoute({this.kind = ''});
  BooksRoute.state(GoRouterState state, {required LocalKey? key})
      : kind = state.params['kind']!,
        super(key: key);

  final String kind;
  String get location => '/books${kind.isEmpty ? '' : '/$kind'}';
  void go(BuildContext context) => context.go(location);

  @override
  Widget build(BuildContext context) => BookstoreScaffold(
        selectedTab: ScaffoldTab.books,
        child: BooksScreen(kind),
      );
}

class BookDetailRoute extends FadeTransitionRoute {
  BookDetailRoute({required this.bookId});
  BookDetailRoute.state(GoRouterState state)
      : this(bookId: int.parse(state.params['bookId']!));

  final int bookId;
  String get location => '/books/all/$bookId';
  void go(BuildContext context) => context.go(location);

  @override
  Widget build(BuildContext context) => BookDetailsScreen(
        book: libraryInstance.allBooks.firstWhereOrNull(
          (b) => b.id == bookId,
        ),
      );
}

class AuthorsRoute extends FadeTransitionRoute {
  AuthorsRoute();
  // ignore: avoid_unused_constructor_parameters
  AuthorsRoute.state(GoRouterState state, {required LocalKey? key})
      : super(key: key);

  String get location => '/authors';
  void go(BuildContext context) => context.go(location);

  @override
  Widget build(BuildContext context) => const BookstoreScaffold(
        selectedTab: ScaffoldTab.authors,
        child: AuthorsScreen(),
      );
}

class AuthorDetailRoute extends FadeTransitionRoute {
  AuthorDetailRoute({required this.authorId});
  AuthorDetailRoute.state(GoRouterState state)
      : this(authorId: int.parse(state.params['authorId']!));

  final int authorId;
  String get location => '/authors/$authorId';
  void go(BuildContext context) => context.go(location);
  void push(BuildContext context) => context.push(location);

  @override
  Widget build(BuildContext context) => AuthorDetailsScreen(
        author: libraryInstance.allAuthors.firstWhereOrNull(
          (a) => a.id == authorId,
        ),
      );
}

class SettingsRoute extends FadeTransitionRoute {
  SettingsRoute();
  // ignore: avoid_unused_constructor_parameters
  SettingsRoute.state(GoRouterState state, {required LocalKey? key})
      : super(key: key);

  final String location = '/settings';
  void go(BuildContext context) => context.go(location);

  @override
  Widget build(BuildContext context) => const BookstoreScaffold(
        selectedTab: ScaffoldTab.settings,
        child: SettingsScreen(),
      );
}

class ErrorRoute extends FadeTransitionRoute {
  ErrorRoute.state(GoRouterState state) : error = state.error!;
  final Exception error;

  @override
  Widget build(BuildContext context) => ErrorScreen(error);
}
