import 'package:auto_route/auto_route.dart';

import 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.material();

  @override
  List<AutoRoute> get routes => [
        AutoRoute(path: '/', page: HomeRoute.page, initial: true),
        // AutoRoute(path: '/auth'),
        AutoRoute(path: '/auth/info', page: InfoRoute.page),
        AutoRoute(path: '/auth/login', page: LoginRoute.page),
        AutoRoute(path: '/auth/register', page: RegisterRoute.page),
        AutoRoute(path: '/hitomi', page: HitomiRoute.page),
        AutoRoute(path: '/hitomi/ids', page: IdRoute.page),
        AutoRoute(path: '/hitomi/:id', page: HitomiReaderRoute.page),
        AutoRoute(path: '/gallery-analysis/:id', page: GalleryAnalysisRoute.page),
        AutoRoute(path: '/batch-analysis', page: BatchAnalysisRoute.page),
        AutoRoute(path: '/settings', page: SettingRoute.page),
        AutoRoute(path: '/settings/blacklist', page: BlacklistRoute.page)
      ];
}
