import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hitomiviewer/app_router.dart';
import 'package:hitomiviewer/app_router.gr.dart';
import 'package:hitomiviewer/store.dart';
import 'package:provider/provider.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => Store()),
      ],
      child: MaterialApp.router(
        title: 'Hitomi Viewer',
        routerConfig: _appRouter.config(),
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
    );
  }
}
