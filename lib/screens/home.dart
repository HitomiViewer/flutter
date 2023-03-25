import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final String title;

  const HomeScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: const Text('Hitomi'),
              onPressed: () {
                // Named route를 사용하여 두 번째 화면으로 전환합니다.
                Navigator.pushNamed(context, '/hitomi');
              },
            ),
          ],
        ),
      ),
    );
  }
}
