// Copyright 2021, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:adaptive_navigation/adaptive_navigation.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

class BookstoreScaffold extends StatelessWidget {
  final int selectedIndex;
  final Widget child;

  const BookstoreScaffold({
    required this.selectedIndex,
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: AdaptiveNavigationScaffold(
          selectedIndex: selectedIndex,
          body: child,
          onDestinationSelected: (idx) {
            if (idx == 0) context.go('/books');
            if (idx == 1) context.go('/authors');
            if (idx == 2) context.go('/settings');
          },
          destinations: const [
            AdaptiveScaffoldDestination(
              title: 'Books',
              icon: Icons.book,
            ),
            AdaptiveScaffoldDestination(
              title: 'Authors',
              icon: Icons.person,
            ),
            AdaptiveScaffoldDestination(
              title: 'Settings',
              icon: Icons.settings,
            ),
          ],
        ),
      );
}
