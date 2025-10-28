import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hitomiviewer/app_router.dart';
import 'package:hitomiviewer/services/image_embedding.dart';
import 'package:hitomiviewer/store.dart';
import 'package:provider/provider.dart';
import 'package:onnxruntime/onnxruntime.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ONNX Runtime 환경 초기화
  try {
    debugPrint('🚀 ONNX Runtime 환경 초기화 중...');
    OrtEnv.instance.init();
    debugPrint('✅ ONNX Runtime 환경 초기화 완료');
  } catch (e, stackTrace) {
    debugPrint('❌ ONNX Runtime 초기화 실패:');
    debugPrint('  - 에러: $e');
    debugPrint('  - 스택 트레이스: $stackTrace');
    debugPrint('  - 앱은 계속 실행되지만 AI 기능은 사용할 수 없습니다.');
  }

  // PE-Core 모델 초기화
  final embeddingService = ImageEmbeddingService();
  try {
    debugPrint('🚀 PE-Core 모델 초기화 중...');
    await embeddingService.initialize();
    debugPrint('✅ PE-Core 모델 초기화 완료');
  } catch (e, stackTrace) {
    debugPrint('❌ PE-Core 모델 초기화 실패:');
    debugPrint('  - 에러: $e');
    debugPrint('  - 스택 트레이스: $stackTrace');
    debugPrint('  - 모델 상태: ${embeddingService.status}');
    debugPrint('  - 에러 메시지: ${embeddingService.errorMessage ?? "없음"}');
    debugPrint('  - 앱은 계속 실행되지만 이미지 분석 기능은 사용할 수 없습니다.');
    // 모델 로드 실패해도 앱은 계속 실행
  }

  debugPrint('🚀 앱 실행 중...');
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
