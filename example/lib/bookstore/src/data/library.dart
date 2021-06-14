// Copyright 2021, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';

import 'author.dart';
import 'book.dart';

class Library {
  final List<Book> allBooks = [];
  final List<Author> allAuthors = [];

  static final sample = Library()
    ..addBook(
        title: 'Left Hand of Darkness',
        authorName: 'Ursula K. Le Guin',
        isPopular: true,
        isNew: true)
    ..addBook(
        title: 'Too Like the Lightning',
        authorName: 'Ada Palmer',
        isPopular: false,
        isNew: true)
    ..addBook(
        title: 'Kindred',
        authorName: 'Octavia E. Butler',
        isPopular: true,
        isNew: false)
    ..addBook(
        title: 'The Lathe of Heaven',
        authorName: 'Ursula K. Le Guin',
        isPopular: false,
        isNew: false);

  void addBook({
    required String title,
    required String authorName,
    required bool isPopular,
    required bool isNew,
  }) {
    var author =
        allAuthors.firstWhereOrNull((author) => author.name == authorName);
    final book = Book(
        id: allBooks.length, title: title, isPopular: isPopular, isNew: isNew);

    if (author == null) {
      author = Author(id: allAuthors.length, name: authorName, books: [book]);
      allAuthors.add(author);
    } else {
      author.books.add(book);
    }

    book.author = author;
    allBooks.add(book);
  }

  List<Book> get popularBooks => [
        ...allBooks.where((book) => book.isPopular),
      ];

  List<Book> get newBooks => [
        ...allBooks.where((book) => book.isNew),
      ];

  Book? findBook(int id) => allBooks.firstWhereOrNull((b) => b.id == id);

  Author? findAuthor(int id) => allAuthors.firstWhereOrNull((a) => a.id == id);
}
