// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i12;
import 'package:flutter/material.dart' as _i13;
import 'package:hitomiviewer/screens/auth/info.dart' as _i10;
import 'package:hitomiviewer/screens/auth/login.dart' as _i8;
import 'package:hitomiviewer/screens/auth/register.dart' as _i9;
import 'package:hitomiviewer/screens/favorite.dart' as _i1;
import 'package:hitomiviewer/screens/hitomi.dart' as _i3;
import 'package:hitomiviewer/screens/hitomi/reader.dart' as _i2;
import 'package:hitomiviewer/screens/home.dart' as _i4;
import 'package:hitomiviewer/screens/idlist.dart' as _i5;
import 'package:hitomiviewer/screens/search.dart' as _i11;
import 'package:hitomiviewer/screens/settings.dart' as _i7;
import 'package:hitomiviewer/screens/settings/blacklist.dart' as _i6;

abstract class $AppRouter extends _i12.RootStackRouter {
  $AppRouter({super.navigatorKey});

  @override
  final Map<String, _i12.PageFactory> pagesMap = {
    FavoriteRoute.name: (routeData) {
      return _i12.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i1.FavoriteScreen(),
      );
    },
    HitomiReaderRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<HitomiReaderRouteArgs>(
          orElse: () => HitomiReaderRouteArgs(id: pathParams.optInt('id')));
      return _i12.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i2.HitomiReaderScreen(
          key: args.key,
          id: args.id,
          isFullScreen: args.isFullScreen,
          initialPage: args.initialPage,
        ),
      );
    },
    HitomiRoute.name: (routeData) {
      final args = routeData.argsAs<HitomiRouteArgs>(
          orElse: () => const HitomiRouteArgs());
      return _i12.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i3.HitomiScreen(
          key: args.key,
          query: args.query,
        ),
      );
    },
    HomeRoute.name: (routeData) {
      return _i12.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i4.HomeScreen(),
      );
    },
    IdRoute.name: (routeData) {
      final args = routeData.argsAs<IdRouteArgs>();
      return _i12.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i5.IdScreen(
          key: args.key,
          ids: args.ids,
        ),
      );
    },
    BlacklistRoute.name: (routeData) {
      return _i12.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i6.BlacklistScreen(),
      );
    },
    SettingRoute.name: (routeData) {
      return _i12.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i7.SettingScreen(),
      );
    },
    LoginRoute.name: (routeData) {
      return _i12.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i8.LoginScreen(),
      );
    },
    RegisterRoute.name: (routeData) {
      return _i12.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i9.RegisterScreen(),
      );
    },
    InfoRoute.name: (routeData) {
      return _i12.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i10.InfoScreen(),
      );
    },
    SearchRoute.name: (routeData) {
      return _i12.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i11.SearchScreen(),
      );
    },
  };
}

/// generated route for
/// [_i1.FavoriteScreen]
class FavoriteRoute extends _i12.PageRouteInfo<void> {
  const FavoriteRoute({List<_i12.PageRouteInfo>? children})
      : super(
          FavoriteRoute.name,
          initialChildren: children,
        );

  static const String name = 'FavoriteRoute';

  static const _i12.PageInfo<void> page = _i12.PageInfo<void>(name);
}

/// generated route for
/// [_i2.HitomiReaderScreen]
class HitomiReaderRoute extends _i12.PageRouteInfo<HitomiReaderRouteArgs> {
  HitomiReaderRoute({
    _i13.Key? key,
    required int? id,
    bool isFullScreen = false,
    int initialPage = 0,
    List<_i12.PageRouteInfo>? children,
  }) : super(
          HitomiReaderRoute.name,
          args: HitomiReaderRouteArgs(
            key: key,
            id: id,
            isFullScreen: isFullScreen,
            initialPage: initialPage,
          ),
          rawPathParams: {'id': id},
          initialChildren: children,
        );

  static const String name = 'HitomiReaderRoute';

  static const _i12.PageInfo<HitomiReaderRouteArgs> page =
      _i12.PageInfo<HitomiReaderRouteArgs>(name);
}

class HitomiReaderRouteArgs {
  const HitomiReaderRouteArgs({
    this.key,
    required this.id,
    this.isFullScreen = false,
    this.initialPage = 0,
  });

  final _i13.Key? key;

  final int? id;

  final bool isFullScreen;

  final int initialPage;

  @override
  String toString() {
    return 'HitomiReaderRouteArgs{key: $key, id: $id, isFullScreen: $isFullScreen, initialPage: $initialPage}';
  }
}

/// generated route for
/// [_i3.HitomiScreen]
class HitomiRoute extends _i12.PageRouteInfo<HitomiRouteArgs> {
  HitomiRoute({
    _i13.Key? key,
    String? query,
    List<_i12.PageRouteInfo>? children,
  }) : super(
          HitomiRoute.name,
          args: HitomiRouteArgs(
            key: key,
            query: query,
          ),
          initialChildren: children,
        );

  static const String name = 'HitomiRoute';

  static const _i12.PageInfo<HitomiRouteArgs> page =
      _i12.PageInfo<HitomiRouteArgs>(name);
}

class HitomiRouteArgs {
  const HitomiRouteArgs({
    this.key,
    this.query,
  });

  final _i13.Key? key;

  final String? query;

  @override
  String toString() {
    return 'HitomiRouteArgs{key: $key, query: $query}';
  }
}

/// generated route for
/// [_i4.HomeScreen]
class HomeRoute extends _i12.PageRouteInfo<void> {
  const HomeRoute({List<_i12.PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static const _i12.PageInfo<void> page = _i12.PageInfo<void>(name);
}

/// generated route for
/// [_i5.IdScreen]
class IdRoute extends _i12.PageRouteInfo<IdRouteArgs> {
  IdRoute({
    _i13.Key? key,
    required List<int> ids,
    List<_i12.PageRouteInfo>? children,
  }) : super(
          IdRoute.name,
          args: IdRouteArgs(
            key: key,
            ids: ids,
          ),
          initialChildren: children,
        );

  static const String name = 'IdRoute';

  static const _i12.PageInfo<IdRouteArgs> page =
      _i12.PageInfo<IdRouteArgs>(name);
}

class IdRouteArgs {
  const IdRouteArgs({
    this.key,
    required this.ids,
  });

  final _i13.Key? key;

  final List<int> ids;

  @override
  String toString() {
    return 'IdRouteArgs{key: $key, ids: $ids}';
  }
}

/// generated route for
/// [_i6.BlacklistScreen]
class BlacklistRoute extends _i12.PageRouteInfo<void> {
  const BlacklistRoute({List<_i12.PageRouteInfo>? children})
      : super(
          BlacklistRoute.name,
          initialChildren: children,
        );

  static const String name = 'BlacklistRoute';

  static const _i12.PageInfo<void> page = _i12.PageInfo<void>(name);
}

/// generated route for
/// [_i7.SettingScreen]
class SettingRoute extends _i12.PageRouteInfo<void> {
  const SettingRoute({List<_i12.PageRouteInfo>? children})
      : super(
          SettingRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingRoute';

  static const _i12.PageInfo<void> page = _i12.PageInfo<void>(name);
}

/// generated route for
/// [_i8.LoginScreen]
class LoginRoute extends _i12.PageRouteInfo<void> {
  const LoginRoute({List<_i12.PageRouteInfo>? children})
      : super(
          LoginRoute.name,
          initialChildren: children,
        );

  static const String name = 'LoginRoute';

  static const _i12.PageInfo<void> page = _i12.PageInfo<void>(name);
}

/// generated route for
/// [_i9.RegisterScreen]
class RegisterRoute extends _i12.PageRouteInfo<void> {
  const RegisterRoute({List<_i12.PageRouteInfo>? children})
      : super(
          RegisterRoute.name,
          initialChildren: children,
        );

  static const String name = 'RegisterRoute';

  static const _i12.PageInfo<void> page = _i12.PageInfo<void>(name);
}

/// generated route for
/// [_i10.InfoScreen]
class InfoRoute extends _i12.PageRouteInfo<void> {
  const InfoRoute({List<_i12.PageRouteInfo>? children})
      : super(
          InfoRoute.name,
          initialChildren: children,
        );

  static const String name = 'InfoRoute';

  static const _i12.PageInfo<void> page = _i12.PageInfo<void>(name);
}

/// generated route for
/// [_i11.SearchScreen]
class SearchRoute extends _i12.PageRouteInfo<void> {
  const SearchRoute({List<_i12.PageRouteInfo>? children})
      : super(
          SearchRoute.name,
          initialChildren: children,
        );

  static const String name = 'SearchRoute';

  static const _i12.PageInfo<void> page = _i12.PageInfo<void>(name);
}
