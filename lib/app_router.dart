import 'package:auto_route/auto_route.dart';

import 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends $AppRouter {
  @override
  RouteType get defaultRouteType => const RouteType.material();

  @override
  List<AutoRoute> get routes => [
        AutoRoute(path: '/', page: HomeRoute.page, initial: true),
        AutoRoute(path: '/hitomi', page: HitomiRoute.page),
        AutoRoute(path: '/hitomi/:id', page: HitomiReaderRoute.page),
        AutoRoute(path: '/settings', page: SettingRoute.page),
        AutoRoute(path: '/settings/blacklist', page: BlacklistRoute.page)
      ];
}
