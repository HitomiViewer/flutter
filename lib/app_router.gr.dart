// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i14;
import 'package:collection/collection.dart' as _i16;
import 'package:flutter/material.dart' as _i15;
import 'package:hitomiviewer/screens/auth/info.dart' as _i9;
import 'package:hitomiviewer/screens/auth/login.dart' as _i10;
import 'package:hitomiviewer/screens/auth/register.dart' as _i11;
import 'package:hitomiviewer/screens/batch_analysis/batch_analysis.dart' as _i1;
import 'package:hitomiviewer/screens/favorite/favorite.dart' as _i3;
import 'package:hitomiviewer/screens/gallery_analysis/gallery_analysis.dart'
    as _i4;
import 'package:hitomiviewer/screens/hitomi/hitomi.dart' as _i6;
import 'package:hitomiviewer/screens/hitomi/reader.dart' as _i5;
import 'package:hitomiviewer/screens/home/home.dart' as _i7;
import 'package:hitomiviewer/screens/search/search.dart' as _i12;
import 'package:hitomiviewer/screens/settings/blacklist.dart' as _i2;
import 'package:hitomiviewer/screens/settings/settings.dart' as _i13;
import 'package:hitomiviewer/screens/view/idlist.dart' as _i8;

/// generated route for
/// [_i1.BatchAnalysisScreen]
class BatchAnalysisRoute extends _i14.PageRouteInfo<void> {
  const BatchAnalysisRoute({List<_i14.PageRouteInfo>? children})
      : super(BatchAnalysisRoute.name, initialChildren: children);

  static const String name = 'BatchAnalysisRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      return const _i1.BatchAnalysisScreen();
    },
  );
}

/// generated route for
/// [_i2.BlacklistScreen]
class BlacklistRoute extends _i14.PageRouteInfo<void> {
  const BlacklistRoute({List<_i14.PageRouteInfo>? children})
      : super(BlacklistRoute.name, initialChildren: children);

  static const String name = 'BlacklistRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      return const _i2.BlacklistScreen();
    },
  );
}

/// generated route for
/// [_i3.FavoriteScreen]
class FavoriteRoute extends _i14.PageRouteInfo<void> {
  const FavoriteRoute({List<_i14.PageRouteInfo>? children})
      : super(FavoriteRoute.name, initialChildren: children);

  static const String name = 'FavoriteRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      return const _i3.FavoriteScreen();
    },
  );
}

/// generated route for
/// [_i4.GalleryAnalysisScreen]
class GalleryAnalysisRoute
    extends _i14.PageRouteInfo<GalleryAnalysisRouteArgs> {
  GalleryAnalysisRoute({
    _i15.Key? key,
    required int id,
    List<_i14.PageRouteInfo>? children,
  }) : super(
          GalleryAnalysisRoute.name,
          args: GalleryAnalysisRouteArgs(key: key, id: id),
          rawPathParams: {'id': id},
          initialChildren: children,
        );

  static const String name = 'GalleryAnalysisRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<GalleryAnalysisRouteArgs>(
        orElse: () => GalleryAnalysisRouteArgs(id: pathParams.getInt('id')),
      );
      return _i4.GalleryAnalysisScreen(key: args.key, id: args.id);
    },
  );
}

class GalleryAnalysisRouteArgs {
  const GalleryAnalysisRouteArgs({this.key, required this.id});

  final _i15.Key? key;

  final int id;

  @override
  String toString() {
    return 'GalleryAnalysisRouteArgs{key: $key, id: $id}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GalleryAnalysisRouteArgs) return false;
    return key == other.key && id == other.id;
  }

  @override
  int get hashCode => key.hashCode ^ id.hashCode;
}

/// generated route for
/// [_i5.HitomiReaderScreen]
class HitomiReaderRoute extends _i14.PageRouteInfo<HitomiReaderRouteArgs> {
  HitomiReaderRoute({
    _i15.Key? key,
    required int? id,
    bool isFullScreen = false,
    int initialPage = 0,
    List<_i14.PageRouteInfo>? children,
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

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<HitomiReaderRouteArgs>(
        orElse: () => HitomiReaderRouteArgs(id: pathParams.optInt('id')),
      );
      return _i5.HitomiReaderScreen(
        key: args.key,
        id: args.id,
        isFullScreen: args.isFullScreen,
        initialPage: args.initialPage,
      );
    },
  );
}

class HitomiReaderRouteArgs {
  const HitomiReaderRouteArgs({
    this.key,
    required this.id,
    this.isFullScreen = false,
    this.initialPage = 0,
  });

  final _i15.Key? key;

  final int? id;

  final bool isFullScreen;

  final int initialPage;

  @override
  String toString() {
    return 'HitomiReaderRouteArgs{key: $key, id: $id, isFullScreen: $isFullScreen, initialPage: $initialPage}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HitomiReaderRouteArgs) return false;
    return key == other.key &&
        id == other.id &&
        isFullScreen == other.isFullScreen &&
        initialPage == other.initialPage;
  }

  @override
  int get hashCode =>
      key.hashCode ^ id.hashCode ^ isFullScreen.hashCode ^ initialPage.hashCode;
}

/// generated route for
/// [_i6.HitomiScreen]
class HitomiRoute extends _i14.PageRouteInfo<HitomiRouteArgs> {
  HitomiRoute({
    _i15.Key? key,
    String? query,
    List<_i14.PageRouteInfo>? children,
  }) : super(
          HitomiRoute.name,
          args: HitomiRouteArgs(key: key, query: query),
          initialChildren: children,
        );

  static const String name = 'HitomiRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<HitomiRouteArgs>(
        orElse: () => const HitomiRouteArgs(),
      );
      return _i6.HitomiScreen(key: args.key, query: args.query);
    },
  );
}

class HitomiRouteArgs {
  const HitomiRouteArgs({this.key, this.query});

  final _i15.Key? key;

  final String? query;

  @override
  String toString() {
    return 'HitomiRouteArgs{key: $key, query: $query}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HitomiRouteArgs) return false;
    return key == other.key && query == other.query;
  }

  @override
  int get hashCode => key.hashCode ^ query.hashCode;
}

/// generated route for
/// [_i7.HomeScreen]
class HomeRoute extends _i14.PageRouteInfo<void> {
  const HomeRoute({List<_i14.PageRouteInfo>? children})
      : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      return const _i7.HomeScreen();
    },
  );
}

/// generated route for
/// [_i8.IdScreen]
class IdRoute extends _i14.PageRouteInfo<IdRouteArgs> {
  IdRoute({
    _i15.Key? key,
    required List<int> ids,
    List<_i14.PageRouteInfo>? children,
  }) : super(
          IdRoute.name,
          args: IdRouteArgs(key: key, ids: ids),
          initialChildren: children,
        );

  static const String name = 'IdRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<IdRouteArgs>();
      return _i8.IdScreen(key: args.key, ids: args.ids);
    },
  );
}

class IdRouteArgs {
  const IdRouteArgs({this.key, required this.ids});

  final _i15.Key? key;

  final List<int> ids;

  @override
  String toString() {
    return 'IdRouteArgs{key: $key, ids: $ids}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! IdRouteArgs) return false;
    return key == other.key &&
        const _i16.ListEquality<int>().equals(ids, other.ids);
  }

  @override
  int get hashCode => key.hashCode ^ const _i16.ListEquality<int>().hash(ids);
}

/// generated route for
/// [_i9.InfoScreen]
class InfoRoute extends _i14.PageRouteInfo<void> {
  const InfoRoute({List<_i14.PageRouteInfo>? children})
      : super(InfoRoute.name, initialChildren: children);

  static const String name = 'InfoRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      return const _i9.InfoScreen();
    },
  );
}

/// generated route for
/// [_i10.LoginScreen]
class LoginRoute extends _i14.PageRouteInfo<void> {
  const LoginRoute({List<_i14.PageRouteInfo>? children})
      : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      return const _i10.LoginScreen();
    },
  );
}

/// generated route for
/// [_i11.RegisterScreen]
class RegisterRoute extends _i14.PageRouteInfo<void> {
  const RegisterRoute({List<_i14.PageRouteInfo>? children})
      : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      return const _i11.RegisterScreen();
    },
  );
}

/// generated route for
/// [_i12.SearchScreen]
class SearchRoute extends _i14.PageRouteInfo<SearchRouteArgs> {
  SearchRoute({_i15.Key? key, List<_i14.PageRouteInfo>? children})
      : super(
          SearchRoute.name,
          args: SearchRouteArgs(key: key),
          initialChildren: children,
        );

  static const String name = 'SearchRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SearchRouteArgs>(
        orElse: () => const SearchRouteArgs(),
      );
      return _i12.SearchScreen(key: args.key);
    },
  );
}

class SearchRouteArgs {
  const SearchRouteArgs({this.key});

  final _i15.Key? key;

  @override
  String toString() {
    return 'SearchRouteArgs{key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SearchRouteArgs) return false;
    return key == other.key;
  }

  @override
  int get hashCode => key.hashCode;
}

/// generated route for
/// [_i13.SettingScreen]
class SettingRoute extends _i14.PageRouteInfo<void> {
  const SettingRoute({List<_i14.PageRouteInfo>? children})
      : super(SettingRoute.name, initialChildren: children);

  static const String name = 'SettingRoute';

  static _i14.PageInfo page = _i14.PageInfo(
    name,
    builder: (data) {
      return const _i13.SettingScreen();
    },
  );
}
