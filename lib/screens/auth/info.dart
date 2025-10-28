import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
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
      try {
        String accessToken = await refresh(store.refreshToken);
        store.setAccessToken(accessToken);
        
        try {
          final value = await getUserInfo(accessToken);
          setState(() {
            _id = value.id;
            _name = value.name;
            _email = value.email;
            _avatar = value.avatar;
          });
        } catch (e, stackTrace) {
          debugPrint('❌ getUserInfo 에러:');
          debugPrint('  - 에러: $e');
          debugPrint('  - 스택 트레이스: $stackTrace');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('사용자 정보 조회 실패: $e'),
              duration: const Duration(seconds: 5),
            ));
          }
        }
      } catch (e, stackTrace) {
        debugPrint('❌ refresh 에러:');
        debugPrint('  - 에러: $e');
        debugPrint('  - 스택 트레이스: $stackTrace');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('토큰 갱신 실패: $e'),
            duration: const Duration(seconds: 5),
          ));
        }
      }
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
