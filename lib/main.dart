import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'screens/home.dart';
import 'screens/hitomi.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

void main() {
  runApp(MaterialApp(
    title: 'Flutter Demo',
    initialRoute: '/',
    routes: {
      '/': (context) => const HomeScreen(title: 'Flutter Demo Home Page'),
      '/hitomi': (context) => const HitomiScreen(),
      '/hitomi/detail': (context) => const HitomiDetailScreen(),
    },
    scrollBehavior: AppScrollBehavior(),
  ));
}
