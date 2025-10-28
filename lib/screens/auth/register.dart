import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hitomiviewer/services/auth.dart';
import 'package:hitomiviewer/store.dart';
import 'package:provider/provider.dart';

@RoutePage()
class RegisterScreen extends StatefulWidget {
  static const String id = 'register_screen';
  final String title = 'Register';

  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  TextEditingController idController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  void regist(String id, String password) async {
    try {
      Tokens token = await signup(id, password);
      context.read<Store>().setAccessToken(token.accessToken);
      context.read<Store>().setRefreshToken(token.refreshToken);
      context.router.pop();
    } catch (e, stackTrace) {
      debugPrint('❌ 회원가입 에러:');
      debugPrint('  - ID: $id');
      debugPrint('  - 에러: $e');
      debugPrint('  - 스택 트레이스: $stackTrace');
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        duration: const Duration(seconds: 5),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Register'),
        ),
        body: Center(
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
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                ),
                controller: passwordController,
              ),
              ElevatedButton(
                onPressed: () =>
                    regist(idController.text, passwordController.text),
                child: const Text('Register'),
              ),
            ],
          ),
        ));
  }
}
