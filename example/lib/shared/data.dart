import 'package:flutter/foundation.dart';

class Person {
  final String id;
  final String name;
  final int age;
  Person({required this.id, required this.name, required this.age});
}

class Family {
  final String id;
  final String name;
  final List<Person> people;
  Family({required this.id, required this.name, required this.people});

  Person person(String pid) => people.singleWhere(
        (p) => p.id == pid,
        orElse: () => throw Exception('unknown person $pid for family $id'),
      );
}

class Families {
  static final data = [
    Family(
      id: 'f1',
      name: 'Sells',
      people: [
        Person(id: 'p1', name: 'Chris', age: 50),
        Person(id: 'p2', name: 'John', age: 25),
        Person(id: 'p3', name: 'Tom', age: 24),
      ],
    ),
    Family(
      id: 'f2',
      name: 'Addams',
      people: [
        Person(id: 'p1', name: 'Gomez', age: 55),
        Person(id: 'p2', name: 'Morticia', age: 50),
        Person(id: 'p3', name: 'Pugsley', age: 10),
        Person(id: 'p4', name: 'Wednesday', age: 17),
      ],
    ),
  ];

  static Family family(String fid) => data.singleWhere(
        (f) => f.id == fid,
        orElse: () => throw Exception('unknown family $fid'),
      );
}

class LoginInfo extends ChangeNotifier {
  var _userName = '';

  bool get loggedIn => _userName.isNotEmpty;
  String get userName => _userName;

  void login(String userName) {
    _userName = userName;
    notifyListeners();
  }

  void logout() => login('');
}
