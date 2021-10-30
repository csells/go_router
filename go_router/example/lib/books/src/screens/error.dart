import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen(this.error, {Key? key}) : super(key: key);

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
