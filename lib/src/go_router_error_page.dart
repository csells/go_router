import 'package:flutter/material.dart';

/// Default error page implementation for Material.
class GoRouterMaterialErrorPage extends StatelessWidget {
  /// Provide an exception to this page for it to be displayed.
  const GoRouterMaterialErrorPage(this.error, {Key? key}) : super(key: key);

  /// The exception to be displayed.
  final Exception? error;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error?.toString() ?? 'page not found'),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Home'),
              ),
            ],
          ),
        ),
      );
}
