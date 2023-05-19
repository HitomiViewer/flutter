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
      '/': (context) => const HomeScreen(),
      '/hitomi': (context) => const HitomiScreen(),
      '/hitomi/detail': (context) => const HitomiDetailScreen(),
    },
    theme: ThemeData(
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blueGrey,
        accentColor: Colors.blueGrey,
        brightness: Brightness.light,
      ),
    ),
    darkTheme: ThemeData.dark(),
    themeMode: ThemeMode.light,
    scrollBehavior: AppScrollBehavior(),
  ));
}
