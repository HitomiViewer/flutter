import 'package:flutter/material.dart';

import 'hitomi.dart';

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
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Search',
              ),
              onSubmitted: (String query) {
                Navigator.pushNamed(
                  context,
                  '/hitomi',
                  arguments: HitomiScreenArguments(query: query),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
