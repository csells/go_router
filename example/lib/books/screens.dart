// Copyright 2021, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'data.dart';

class BooksScreen extends StatefulWidget {
  final String tab;
  const BooksScreen(this.tab, {Key? key}) : super(key: key);

  @override
  _BooksScreenState createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    switch (widget.tab) {
      case 'popular':
        _tabController.index = 0;
        break;
      case 'new':
        _tabController.index = 1;
        break;
      case 'all':
      default:
        _tabController.index = 2;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = Library.sample;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Books'),
        bottom: TabBar(
          controller: _tabController,
          onTap: _tap,
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
          BookList(books: library.popularBooks),
          BookList(books: library.newBooks),
          BookList(books: library.allBooks),
        ],
      ),
    );
  }

  String get title {
    switch (_tabController.index) {
      case 0:
        return 'Popular';
      case 1:
        return 'New';
      case 2:
      default:
        return 'All';
    }
  }

  void _tap(int value) {
    switch (_tabController.index) {
      case 0:
        context.go('/books/popular');
        break;
      case 1:
        context.go('/books/new');
        break;
      case 2:
      default:
        context.go('/books/all');
        break;
    }
  }
}

class BookList extends StatelessWidget {
  final List<Book> books;
  final ValueChanged<Book>? onTap;
  const BookList({required this.books, this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => ListView.builder(
        itemCount: books.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(books[index].title),
          subtitle: Text(books[index].authorName),
          onTap: onTap != null ? () => onTap!(books[index]) : null,
        ),
      );
}

class ErrorScreen extends StatelessWidget {
  final Exception? error;
  const ErrorScreen(this.error, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(body: Text(error.toString()));
}
