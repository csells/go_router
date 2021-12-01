// ignore_for_file: diagnostic_describe_all_properties

import 'package:flutter/cupertino.dart';
import '../go_router.dart';

/// Checks for CupertinoApp in the widget tree.
bool isCupertinoApp(Element elem) =>
    elem.findAncestorWidgetOfExactType<CupertinoApp>() != null;

/// Builds a Cupertino page.
CupertinoPage<void> pageBuilderForCupertinoApp(
  LocalKey key,
  String restorationId,
  Widget child,
) =>
    CupertinoPage<void>(
      key: key,
      restorationId: restorationId,
      child: child,
    );

/// Default error page implementation for Cupertino.
class GoRouterCupertinoErrorScreen extends StatelessWidget {
  /// Provide an exception to this page for it to be displayed.
  const GoRouterCupertinoErrorScreen(this.error, {Key? key}) : super(key: key);

  /// The exception to be displayed.
  final Exception? error;

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
        navigationBar:
            const CupertinoNavigationBar(middle: Text('Page Not Found')),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error?.toString() ?? 'page not found'),
              CupertinoButton(
                onPressed: () => context.go('/'),
                child: const Text('Home'),
              ),
            ],
          ),
        ),
      );
}
