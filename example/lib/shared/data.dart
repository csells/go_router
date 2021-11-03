import 'package:flutter/foundation.dart';

enum PersonDetails {
  hobbies,
  favoriteFood,
  favoriteSport,
}

/// sample Person class
class Person {
  Person({
    required this.id,
    required this.name,
    required this.age,
    this.details = const {},
  });

  final int id;
  final String name;
  final int age;

  final Map<PersonDetails, String> details;
}

/// sample Family class
class Family {
  Family({required this.id, required this.name, required this.people});

  final String id;
  final String name;
  final List<Person> people;

  Person person(int pid) => people.singleWhere(
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
        Person(id: 1, name: 'Chris', age: 52, details: {
          PersonDetails.hobbies: 'coding',
          PersonDetails.favoriteFood: 'all of the above',
          PersonDetails.favoriteSport: 'football?'
        }),
        Person(id: 2, name: 'John', age: 27),
        Person(id: 3, name: 'Tom', age: 26),
      ],
    ),
    Family(
      id: 'f2',
      name: 'Addams',
      people: [
        Person(id: 1, name: 'Gomez', age: 55),
        Person(id: 2, name: 'Morticia', age: 50),
        Person(id: 3, name: 'Pugsley', age: 10),
        Person(id: 4, name: 'Wednesday', age: 17),
      ],
    ),
    Family(
      id: 'f3',
      name: 'Hunting',
      people: [
        Person(id: 1, name: 'Mom', age: 54),
        Person(id: 2, name: 'Dad', age: 55),
        Person(id: 3, name: 'Will', age: 20),
        Person(id: 4, name: 'Marky', age: 21),
        Person(id: 5, name: 'Ricky', age: 22),
        Person(id: 6, name: 'Danny', age: 23),
        Person(id: 7, name: 'Terry', age: 24),
        Person(id: 8, name: 'Mikey', age: 25),
        Person(id: 9, name: 'Davey', age: 26),
        Person(id: 10, name: 'Timmy', age: 27),
        Person(id: 11, name: 'Tommy', age: 28),
        Person(id: 12, name: 'Joey', age: 29),
        Person(id: 13, name: 'Robby', age: 30),
        Person(id: 14, name: 'Johnny', age: 31),
        Person(id: 15, name: 'Brian', age: 32),
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

  Future<FamilyPerson> getPerson(String fid, int pid) async {
    final family = await getFamily(fid);
    return FamilyPerson(family: family, person: family.person(pid));
  }
}
