// Copyright 2021, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data.dart';

class AuthorList extends StatelessWidget {
  final List<Author> authors;
  const AuthorList({required this.authors, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => ListView.builder(
        itemCount: authors.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(authors[index].name),
          subtitle: Text('${authors[index].books.length} books'),
          onTap: () => _tap(context, authors[index]),
        ),
      );

  void _tap(BuildContext context, Author author) =>
      context.go('/author/${author.id}');
}
