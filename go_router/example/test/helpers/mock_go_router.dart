import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router/src/inherited_go_router.dart';

import 'package:mocktail/mocktail.dart';

class MockGoRouter extends Mock implements GoRouter {}

/// {@template mock_navigator_provider}
/// The widget that provides an instance of a [MockGoRouter].
/// {@endtemplate}
class MockGoRouterProvider extends StatelessWidget {
  /// {@macro mock_navigator_provider}
  const MockGoRouterProvider({
    required this.goRouter,
    required this.child,
    Key? key,
  }) : super(key: key);

  /// The mock navigator used to mock navigation calls.
  final GoRouter goRouter;

  /// The [Widget] to render.
  final Widget child;

  @override
  Widget build(BuildContext context) => InheritedGoRouter(
        goRouter: goRouter,
        child: child,
      );
}
