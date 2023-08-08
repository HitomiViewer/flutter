// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i6;
import 'package:flutter/material.dart' as _i7;
import 'package:hitomiviewer/screens/hitomi.dart' as _i2;
import 'package:hitomiviewer/screens/hitomi/reader.dart' as _i1;
import 'package:hitomiviewer/screens/home.dart' as _i3;
import 'package:hitomiviewer/screens/settings.dart' as _i5;
import 'package:hitomiviewer/screens/settings/blacklist.dart' as _i4;

abstract class $AppRouter extends _i6.RootStackRouter {
  $AppRouter({super.navigatorKey});

  @override
  final Map<String, _i6.PageFactory> pagesMap = {
    HitomiReaderRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<HitomiReaderRouteArgs>(
          orElse: () => HitomiReaderRouteArgs(id: pathParams.optInt('id')));
      return _i6.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i1.HitomiReaderScreen(
          key: args.key,
          id: args.id,
          isFullScreen: args.isFullScreen,
        ),
      );
    },
    HitomiRoute.name: (routeData) {
      final args = routeData.argsAs<HitomiRouteArgs>(
          orElse: () => const HitomiRouteArgs());
      return _i6.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i2.HitomiScreen(
          key: args.key,
          query: args.query,
        ),
      );
    },
    HomeRoute.name: (routeData) {
      return _i6.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i3.HomeScreen(),
      );
    },
    SearchRoute.name: (routeData) {
      return _i6.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i3.SearchScreen(),
      );
    },
    BlacklistRoute.name: (routeData) {
      return _i6.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i4.BlacklistScreen(),
      );
    },
    SettingRoute.name: (routeData) {
      return _i6.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i5.SettingScreen(),
      );
    },
  };
}

/// generated route for
/// [_i1.HitomiReaderScreen]
class HitomiReaderRoute extends _i6.PageRouteInfo<HitomiReaderRouteArgs> {
  HitomiReaderRoute({
    _i7.Key? key,
    required int? id,
    bool isFullScreen = false,
    List<_i6.PageRouteInfo>? children,
  }) : super(
          HitomiReaderRoute.name,
          args: HitomiReaderRouteArgs(
            key: key,
            id: id,
            isFullScreen: isFullScreen,
          ),
          rawPathParams: {'id': id},
          initialChildren: children,
        );

  static const String name = 'HitomiReaderRoute';

  static const _i6.PageInfo<HitomiReaderRouteArgs> page =
      _i6.PageInfo<HitomiReaderRouteArgs>(name);
}

class HitomiReaderRouteArgs {
  const HitomiReaderRouteArgs({
    this.key,
    required this.id,
    this.isFullScreen = false,
  });

  final _i7.Key? key;

  final int? id;

  final bool isFullScreen;

  @override
  String toString() {
    return 'HitomiReaderRouteArgs{key: $key, id: $id, isFullScreen: $isFullScreen}';
  }
}

/// generated route for
/// [_i2.HitomiScreen]
class HitomiRoute extends _i6.PageRouteInfo<HitomiRouteArgs> {
  HitomiRoute({
    _i7.Key? key,
    String? query,
    List<_i6.PageRouteInfo>? children,
  }) : super(
          HitomiRoute.name,
          args: HitomiRouteArgs(
            key: key,
            query: query,
          ),
          initialChildren: children,
        );

  static const String name = 'HitomiRoute';

  static const _i6.PageInfo<HitomiRouteArgs> page =
      _i6.PageInfo<HitomiRouteArgs>(name);
}

class HitomiRouteArgs {
  const HitomiRouteArgs({
    this.key,
    this.query,
  });

  final _i7.Key? key;

  final String? query;

  @override
  String toString() {
    return 'HitomiRouteArgs{key: $key, query: $query}';
  }
}

/// generated route for
/// [_i3.HomeScreen]
class HomeRoute extends _i6.PageRouteInfo<void> {
  const HomeRoute({List<_i6.PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static const _i6.PageInfo<void> page = _i6.PageInfo<void>(name);
}

/// generated route for
/// [_i3.SearchScreen]
class SearchRoute extends _i6.PageRouteInfo<void> {
  const SearchRoute({List<_i6.PageRouteInfo>? children})
      : super(
          SearchRoute.name,
          initialChildren: children,
        );

  static const String name = 'SearchRoute';

  static const _i6.PageInfo<void> page = _i6.PageInfo<void>(name);
}

/// generated route for
/// [_i4.BlacklistScreen]
class BlacklistRoute extends _i6.PageRouteInfo<void> {
  const BlacklistRoute({List<_i6.PageRouteInfo>? children})
      : super(
          BlacklistRoute.name,
          initialChildren: children,
        );

  static const String name = 'BlacklistRoute';

  static const _i6.PageInfo<void> page = _i6.PageInfo<void>(name);
}

/// generated route for
/// [_i5.SettingScreen]
class SettingRoute extends _i6.PageRouteInfo<void> {
  const SettingRoute({List<_i6.PageRouteInfo>? children})
      : super(
          SettingRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingRoute';

  static const _i6.PageInfo<void> page = _i6.PageInfo<void>(name);
}
