import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'hitomi.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hitomi Viewer'),
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
