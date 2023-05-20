import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hitomiviewer/screens/settings.dart';
import 'package:hitomiviewer/store.dart';
import 'package:provider/provider.dart';

import 'screens/hitomi/reader.dart';
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
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => Store()),
    ],
    child: MaterialApp(
      title: 'Hitomi Viewer',
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/settings': (context) => const SettingScreen(),
        '/hitomi': (context) => const HitomiScreen(),
        '/hitomi/detail': (context) => const HitomiReaderScreen(),
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
    ),
  ));
}
