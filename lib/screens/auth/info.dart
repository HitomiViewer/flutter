import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hitomiviewer/services/auth.dart';
import 'package:hitomiviewer/store.dart';
import 'package:provider/provider.dart';

@RoutePage()
class InfoScreen extends StatefulWidget {
  static const String id = 'login_screen';
  final String title = 'Login';

  const InfoScreen({super.key});

  @override
  _InfoScreenState createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  String? _id;
  String? _name;
  String? _email;
  String? _avatar;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = context.read<Store>();

    (() async {
      String accessToken = await refresh(store.refreshToken);
      store.setAccessToken(accessToken);
      getUserInfo(accessToken).then((value) {
        setState(() {
          _id = value.id;
          _name = value.name;
          _email = value.email;
          _avatar = value.avatar;
        });
      });
    })();
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
            Text("ID: $_id"),
            Text("Name: $_name"),
            Text("Email: $_email"),
            _avatar != null
                ? Image.network(
                    _avatar!,
                    width: 100,
                    height: 100,
                  )
                : const Text("Avatar: null"),
          ],
        ),
      )),
    );
  }
}
