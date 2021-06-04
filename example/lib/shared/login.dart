import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_title(context))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => context.read<LoginInfo>().login('user1'),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );

  static String _title(BuildContext context) =>
      (context as Element).findAncestorWidgetOfExactType<MaterialApp>()!.title;
}
