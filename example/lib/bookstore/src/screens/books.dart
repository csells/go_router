// Copyright 2021, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data.dart';
import '../widgets/book_list.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({Key? key}) : super(key: key);

  @override
  _BooksScreenState createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Library _library;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(_handleTabIndexChanged);
    _library = context.read<Library>();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Books'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                text: 'Popular',
                icon: Icon(Icons.people),
              ),
              Tab(
                text: 'New',
                icon: Icon(Icons.new_releases),
              ),
              Tab(
                text: 'All',
                icon: Icon(Icons.list),
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            BookList(books: _library.popularBooks),
            BookList(books: _library.newBooks),
            BookList(books: _library.allBooks),
          ],
        ),
      );

  String get title {
    switch (_tabController.index) {
      case 1:
        return 'New';
      case 2:
        return 'All';
      case 0:
      default:
        return 'Popular';
    }
  }

  void _handleTabIndexChanged() {
    switch (_tabController.index) {
      case 1:
        context.go('/books/new');
        break;
      case 2:
        context.go('/books/all');
        break;
      case 0:
      default:
        context.go('/books/popular');
        break;
    }
  }

  @override
  void didUpdateWidget(BooksScreen oldWidget) {
    final newPath = GoRouter.of(context).location;
    if (newPath.startsWith('/books/popular')) {
      _tabController.index = 0;
    } else if (newPath.startsWith('/books/new')) {
      _tabController.index = 1;
    } else if (newPath == '/books/all') {
      _tabController.index = 2;
    }
    super.didUpdateWidget(oldWidget);
  }
}
