import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hitomiviewer/app_router.dart';
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

  App({super.key});

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
        themeMode: ThemeMode.system,
        scrollBehavior: AppScrollBehavior(),
        // localizationsDelegates: const [
        //   DefaultMaterialLocalizations.delegate,
        //   DefaultCupertinoLocalizations.delegate,
        //   DefaultWidgetsLocalizations.delegate,
        // ],
        // supportedLocales: const [
        //   Locale('en', 'US'),
        //   Locale('ko', 'KR'),
        // ],
        // // locale: const Locale('ko', 'KR'),
      ),
    );
  }
}
