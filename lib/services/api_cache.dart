import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// API 응답 캐시 모델
class CachedResponse {
  final String data;
  final DateTime cachedAt;
  final Duration ttl;

  CachedResponse({
    required this.data,
    required this.cachedAt,
    required this.ttl,
  });

  bool get isExpired {
    return DateTime.now().difference(cachedAt) > ttl;
  }

  Map<String, dynamic> toJson() => {
        'data': data,
        'cachedAt': cachedAt.toIso8601String(),
        'ttl': ttl.inSeconds,
      };

  factory CachedResponse.fromJson(Map<String, dynamic> json) => CachedResponse(
        data: json['data'],
        cachedAt: DateTime.parse(json['cachedAt']),
        ttl: Duration(seconds: json['ttl']),
      );
}

/// API 캐시 서비스
class ApiCacheService {
  static final ApiCacheService _instance = ApiCacheService._internal();
  factory ApiCacheService() => _instance;
  ApiCacheService._internal();

  static const String _boxName = 'api_cache';
  Box<String>? _box;

  /// 캐시 초기화
  Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox<String>(_boxName);
      debugPrint('✅ API 캐시 초기화 완료');
    } catch (e, stackTrace) {
      debugPrint('❌ API 캐시 초기화 실패:');
      debugPrint('  - 에러: $e');
      debugPrint('  - 스택 트레이스: $stackTrace');
    }
  }

  /// 캐시 저장
  Future<void> set(String key, String data, Duration ttl) async {
    if (_box == null) {
      debugPrint('⚠️  캐시 박스가 초기화되지 않았습니다');
      return;
    }

    try {
      final cachedResponse = CachedResponse(
        data: data,
        cachedAt: DateTime.now(),
        ttl: ttl,
      );

      await _box!.put(key, json.encode(cachedResponse.toJson()));
      debugPrint('💾 캐시 저장: $key (TTL: ${ttl.inMinutes}분)');
    } catch (e, stackTrace) {
      debugPrint('❌ 캐시 저장 실패:');
      debugPrint('  - 키: $key');
      debugPrint('  - 에러: $e');
      debugPrint('  - 스택 트레이스: $stackTrace');
    }
  }

  /// 캐시 조회
  String? get(String key) {
    if (_box == null) {
      return null;
    }

    try {
      final cachedJson = _box!.get(key);
      if (cachedJson == null) {
        debugPrint('📭 캐시 없음: $key');
        return null;
      }

      final cachedResponse = CachedResponse.fromJson(
        json.decode(cachedJson),
      );

      if (cachedResponse.isExpired) {
        debugPrint('⏰ 캐시 만료: $key');
        _box!.delete(key);
        return null;
      }

      final age = DateTime.now().difference(cachedResponse.cachedAt);
      debugPrint('📦 캐시 히트: $key (나이: ${age.inMinutes}분)');
      return cachedResponse.data;
    } catch (e, stackTrace) {
      debugPrint('❌ 캐시 조회 실패:');
      debugPrint('  - 키: $key');
      debugPrint('  - 에러: $e');
      debugPrint('  - 스택 트레이스: $stackTrace');
      return null;
    }
  }

  /// 특정 키로 시작하는 모든 캐시 삭제
  Future<void> deleteByPrefix(String prefix) async {
    if (_box == null) return;

    try {
      final keysToDelete = _box!.keys
          .where((key) => key.toString().startsWith(prefix))
          .toList();

      for (final key in keysToDelete) {
        await _box!.delete(key);
      }

      debugPrint('🗑️  캐시 삭제: $prefix* (${keysToDelete.length}개)');
    } catch (e, stackTrace) {
      debugPrint('❌ 캐시 삭제 실패:');
      debugPrint('  - 접두사: $prefix');
      debugPrint('  - 에러: $e');
      debugPrint('  - 스택 트레이스: $stackTrace');
    }
  }

  /// 특정 키 삭제
  Future<void> delete(String key) async {
    if (_box == null) return;

    try {
      await _box!.delete(key);
      debugPrint('🗑️  캐시 삭제: $key');
    } catch (e, stackTrace) {
      debugPrint('❌ 캐시 삭제 실패:');
      debugPrint('  - 키: $key');
      debugPrint('  - 에러: $e');
      debugPrint('  - 스택 트레이스: $stackTrace');
    }
  }

  /// 모든 캐시 삭제
  Future<void> clearAll() async {
    if (_box == null) return;

    try {
      await _box!.clear();
      debugPrint('🗑️  전체 캐시 삭제');
    } catch (e, stackTrace) {
      debugPrint('❌ 전체 캐시 삭제 실패:');
      debugPrint('  - 에러: $e');
      debugPrint('  - 스택 트레이스: $stackTrace');
    }
  }

  /// 만료된 캐시 정리
  Future<void> cleanExpired() async {
    if (_box == null) return;

    try {
      int deletedCount = 0;
      final keysToDelete = <dynamic>[];

      for (final key in _box!.keys) {
        try {
          final cachedJson = _box!.get(key);
          if (cachedJson != null) {
            final cachedResponse = CachedResponse.fromJson(
              json.decode(cachedJson),
            );

            if (cachedResponse.isExpired) {
              keysToDelete.add(key);
            }
          }
        } catch (e) {
          // 파싱 실패한 캐시도 삭제
          keysToDelete.add(key);
        }
      }

      for (final key in keysToDelete) {
        await _box!.delete(key);
        deletedCount++;
      }

      if (deletedCount > 0) {
        debugPrint('🧹 만료된 캐시 정리: $deletedCount개 삭제');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 만료된 캐시 정리 실패:');
      debugPrint('  - 에러: $e');
      debugPrint('  - 스택 트레이스: $stackTrace');
    }
  }

  /// 캐시 통계
  Map<String, dynamic> getStats() {
    if (_box == null) {
      return {'error': 'Cache not initialized'};
    }

    try {
      int totalCount = _box!.length;
      int expiredCount = 0;
      int validCount = 0;

      for (final key in _box!.keys) {
        try {
          final cachedJson = _box!.get(key);
          if (cachedJson != null) {
            final cachedResponse = CachedResponse.fromJson(
              json.decode(cachedJson),
            );

            if (cachedResponse.isExpired) {
              expiredCount++;
            } else {
              validCount++;
            }
          }
        } catch (e) {
          expiredCount++;
        }
      }

      return {
        'total': totalCount,
        'valid': validCount,
        'expired': expiredCount,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// 모든 캐시 항목 목록 조회
  List<CacheItemInfo> getAllCacheItems() {
    if (_box == null) return [];

    final items = <CacheItemInfo>[];

    for (final key in _box!.keys) {
      try {
        final cachedJson = _box!.get(key);
        if (cachedJson != null) {
          final cachedResponse = CachedResponse.fromJson(
            json.decode(cachedJson),
          );

          items.add(CacheItemInfo(
            key: key.toString(),
            cachedAt: cachedResponse.cachedAt,
            ttl: cachedResponse.ttl,
            isExpired: cachedResponse.isExpired,
            dataSize: cachedResponse.data.length,
          ));
        }
      } catch (e) {
        // 파싱 실패한 항목은 스킵
        debugPrint('⚠️  캐시 항목 파싱 실패: $key - $e');
      }
    }

    // 최신순으로 정렬
    items.sort((a, b) => b.cachedAt.compareTo(a.cachedAt));

    return items;
  }
}

/// 캐시 항목 정보
class CacheItemInfo {
  final String key;
  final DateTime cachedAt;
  final Duration ttl;
  final bool isExpired;
  final int dataSize;

  CacheItemInfo({
    required this.key,
    required this.cachedAt,
    required this.ttl,
    required this.isExpired,
    required this.dataSize,
  });

  Duration get remainingTime {
    if (isExpired) return Duration.zero;
    final elapsed = DateTime.now().difference(cachedAt);
    return ttl - elapsed;
  }

  String get keyType {
    if (key.startsWith('detail:')) return '갤러리 상세';
    if (key.startsWith('posts:')) return '포스트 목록';
    if (key.startsWith('search:')) return '검색 결과';
    if (key.startsWith('autocomplete:')) return '자동완성';
    return '기타';
  }

  String get keyValue {
    final parts = key.split(':');
    if (parts.length > 1) {
      return parts.sublist(1).join(':');
    }
    return key;
  }
}

