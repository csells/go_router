import 'package:flutter/foundation.dart';

/// sample Person class
class Person {
  Person({required this.id, required this.name, required this.age});

  final String id;
  final String name;
  final int age;
}

/// sample Family class
class Family {
  Family({required this.id, required this.name, required this.people});

  final String id;
  final String name;
  final List<Person> people;

  Person person(String pid) => people.singleWhere(
        (p) => p.id == pid,
        orElse: () => throw Exception('unknown person $pid for family $id'),
      );
}

/// sample families data
class Families {
  static final data = [
    Family(
      id: 'f1',
      name: 'Sells',
      people: [
        Person(id: 'p1', name: 'Chris', age: 52),
        Person(id: 'p2', name: 'John', age: 27),
        Person(id: 'p3', name: 'Tom', age: 26),
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
    Family(
      id: 'f3',
      name: 'Jackson',
      people: [
        Person(id: 'p1', name: 'Tito', age: 68),
        Person(id: 'p2', name: 'Jermaine', age: 67),
        Person(id: 'p3', name: 'Jackie', age: 70),
        Person(id: 'p4', name: 'Marlon', age: 64),
        Person(id: 'p5', name: 'Michael', age: 63),
      ],
    ),
  ];

  static Family family(String fid) => data.family(fid);
}

extension on List<Family> {
  Family family(String fid) => singleWhere(
        (f) => f.id == fid,
        orElse: () => throw Exception('unknown family $fid'),
      );
}

/// info about the current login state that notifies listens upon change
class LoginInfo extends ChangeNotifier {
  var _userName = '';
  String get userName => _userName;
  bool get loggedIn => _userName.isNotEmpty;

  void login(String userName) {
    _userName = userName;
    notifyListeners();
  }

  void logout() {
    _userName = '';
    notifyListeners();
  }
}

class FamilyPerson {
  FamilyPerson({required this.family, required this.person});

  final Family family;
  final Person person;
}

class Repository {
  Future<List<Family>> getFamilies() async {
    // simulate network delay
    await Future<void>.delayed(const Duration(seconds: 1));
    return Families.data;
  }

  Future<Family> getFamily(String fid) async =>
      (await getFamilies()).family(fid);

  Future<FamilyPerson> getPerson(String fid, String pid) async {
    final family = await getFamily(fid);
    return FamilyPerson(family: family, person: family.person(pid));
  }
}
