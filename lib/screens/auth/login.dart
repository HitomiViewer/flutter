import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hitomiviewer/services/auth.dart';
import 'package:hitomiviewer/store.dart';
import 'package:provider/provider.dart';

@RoutePage()
class LoginScreen extends StatefulWidget {
  static const String id = 'login_screen';
  final String title = 'Login';

  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController idController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  void login(String id, String password) async {
    try {
      Tokens token = await signin(id, password);
      context.read<Store>().setAccessToken(token.accessToken);
      context.read<Store>().setRefreshToken(token.refreshToken);
      context.router.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'ID',
                ),
                controller: idController,
              ),
              TextField(
                // hide password
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                ),
                obscureText: true,
                controller: passwordController,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => context.router.pushNamed('/auth/register'),
                    child: const Text('Register'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () =>
                        login(idController.text, passwordController.text),
                    child: const Text('Login'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
