import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hitomiviewer/services/auth.dart';
import 'package:hitomiviewer/services/gemma.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Store extends ChangeNotifier {
  SharedPreferences? _prefs;

  Store() {
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      language = prefs.getString('language') ?? language;
      favorite =
          prefs.getStringList('favorite')?.map((e) => int.parse(e)).toList() ??
              favorite;
      blacklist = prefs.getStringList('blacklist') ?? blacklist;
      recent =
          prefs.getStringList('recent')?.map((e) => int.parse(e)).toList() ??
              recent;

      favorite.sort((a, b) => b.compareTo(a));

      refreshToken = prefs.getString('refreshToken') ?? refreshToken;

      // 이미지 분석 결과 로드
      _loadImageAnalysis();
      // 갤러리 임베딩 로드
      _loadGalleryEmbeddings();
      // 이미지 품질 설정 로드
      imageQuality = ImageQuality.values.firstWhere(
        (q) => q.toString() == prefs.getString('imageQuality'),
        orElse: () => ImageQuality.thumbnail,
      );

      notifyListeners();
    }).then((value) async {
      try {
        await refresh(refreshToken).then((value) {
          setAccessToken(value);
        });
      } catch (e) {
        refreshToken = '';
      }
    });
  }

  var accessToken = '';
  setAccessToken(String accessToken) {
    this.accessToken = accessToken;
    notifyListeners();
  }

  var refreshToken = '';
  setRefreshToken(String refreshToken) {
    this.refreshToken = refreshToken;
    _prefs?.setString('refreshToken', refreshToken);
    notifyListeners();
  }

  var language = 'korean';
  setLanguage(String language) {
    this.language = language;
    _prefs?.setString('language', language);
    notifyListeners();
  }

  var favorite = <int>[];
  addFavorite(int id) {
    favorite.add(id);
    favorite.sort((a, b) => b.compareTo(a));
    _prefs?.setStringList(
        'favorite', favorite.map((e) => e.toString()).toList());
    notifyListeners();
  }

  removeFavorite(int id) {
    favorite.remove(id);
    _prefs?.setStringList(
        'favorite', favorite.map((e) => e.toString()).toList());
    notifyListeners();
  }

  removeAtFavorite(int index) {
    favorite.removeAt(index);
    _prefs?.setStringList(
        'favorite', favorite.map((e) => e.toString()).toList());
    notifyListeners();
  }

  toggleFavorite(int id) {
    if (favorite.contains(id)) {
      removeFavorite(id);
    } else {
      addFavorite(id);
    }
  }

  setFavorite(List<int> favorite) {
    this.favorite = favorite;
    this.favorite.sort((a, b) => b.compareTo(a));
    _prefs?.setStringList(
        'favorite', favorite.map((e) => e.toString()).toList());
    notifyListeners();
  }

  mergeFavorite(List<int> favorite) {
    favorite.forEach((element) {
      if (!this.favorite.contains(element)) {
        this.favorite.add(element);
      }
    });
    this.favorite.sort((a, b) => b.compareTo(a));
    _prefs?.setStringList(
        'favorite', this.favorite.map((e) => e.toString()).toList());
    notifyListeners();
  }

  containsFavorite(int id) {
    return favorite.contains(id);
  }

  var blacklist = <String>['male:yaoi'];
  addBlacklist(String tag) {
    blacklist.add(tag);
    _prefs?.setStringList('blacklist', blacklist);
    notifyListeners();
  }

  removeBlacklist(String tag) {
    blacklist.remove(tag);
    _prefs?.setStringList('blacklist', blacklist);
    notifyListeners();
  }

  removeAtBlacklist(int index) {
    blacklist.removeAt(index);
    _prefs?.setStringList('blacklist', blacklist);
    notifyListeners();
  }

  setBlacklist(List<String> blacklist) {
    this.blacklist = blacklist;
    _prefs?.setStringList('blacklist', blacklist);
    notifyListeners();
  }

  var recent = <int>[];
  addRecent(int id) {
    recent.remove(id);
    recent.insert(0, id);
    _prefs?.setStringList(
        'recent',
        recent
            .map((e) => e.toString())
            .toList()
            .sublist(0, min(100, recent.length)));
    notifyListeners();
  }

  // ===== Gemma 이미지 분석 기능 =====

  // 이미지 분석 결과 저장: galleryId -> { 'text': String, 'quality': String, 'timestamp': int }
  var imageAnalysis = <int, Map<String, dynamic>>{};

  // 갤러리 임베딩 저장: galleryId -> embedding vector
  var galleryEmbeddings = <int, List<double>>{};

  // 이미지 품질 설정
  ImageQuality imageQuality = ImageQuality.thumbnail;

  /// 이미지 분석 결과 로드
  void _loadImageAnalysis() {
    final jsonStr = _prefs?.getString('imageAnalysis');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = json.decode(jsonStr);
        imageAnalysis = decoded.map((key, value) => MapEntry(
              int.parse(key),
              Map<String, dynamic>.from(value),
            ));
      } catch (e) {
        debugPrint('이미지 분석 결과 로드 실패: $e');
      }
    }
  }

  /// 갤러리 임베딩 로드
  void _loadGalleryEmbeddings() {
    final jsonStr = _prefs?.getString('galleryEmbeddings');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = json.decode(jsonStr);
        galleryEmbeddings = decoded.map((key, value) => MapEntry(
              int.parse(key),
              List<double>.from(value),
            ));
      } catch (e) {
        debugPrint('갤러리 임베딩 로드 실패: $e');
      }
    }
  }

  /// 이미지 분석 결과 저장
  Future<void> saveImageAnalysis(
    int galleryId,
    String analysis,
    ImageQuality quality,
  ) async {
    imageAnalysis[galleryId] = {
      'text': analysis,
      'quality': quality.toString(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // SharedPreferences에 저장
    final jsonStr = json.encode(imageAnalysis.map(
      (key, value) => MapEntry(key.toString(), value),
    ));
    await _prefs?.setString('imageAnalysis', jsonStr);
    notifyListeners();
  }

  /// 이미지 분석 결과 가져오기
  Map<String, dynamic>? getImageAnalysis(int galleryId) {
    return imageAnalysis[galleryId];
  }

  /// 갤러리 임베딩 저장
  Future<void> saveGalleryEmbedding(
    int galleryId,
    List<double> embedding,
  ) async {
    galleryEmbeddings[galleryId] = embedding;

    // SharedPreferences에 저장
    final jsonStr = json.encode(galleryEmbeddings.map(
      (key, value) => MapEntry(key.toString(), value),
    ));
    await _prefs?.setString('galleryEmbeddings', jsonStr);
    notifyListeners();
  }

  /// 추천도 계산 (0-100)
  double? calculateRecommendationScore(int galleryId) {
    // 현재 갤러리의 임베딩이 없으면 null 반환
    if (!galleryEmbeddings.containsKey(galleryId)) {
      return null;
    }

    final currentEmbedding = galleryEmbeddings[galleryId]!;

    // 좋아요한 갤러리들의 임베딩 가져오기
    final favoriteEmbeddings = <List<double>>[];
    for (var favId in favorite) {
      if (galleryEmbeddings.containsKey(favId) && favId != galleryId) {
        favoriteEmbeddings.add(galleryEmbeddings[favId]!);
      }
    }

    // 좋아요한 갤러리가 없으면 null 반환
    if (favoriteEmbeddings.isEmpty) {
      return null;
    }

    // 각 좋아요 갤러리와의 유사도 계산
    final gemmaService = GemmaService();
    final similarities = <double>[];
    for (var favEmbedding in favoriteEmbeddings) {
      final similarity =
          gemmaService.calculateSimilarity(currentEmbedding, favEmbedding);
      similarities.add(similarity);
    }

    // 평균 유사도 계산
    final avgSimilarity =
        similarities.reduce((a, b) => a + b) / similarities.length;

    // 0-100 범위로 변환 (-1~1 -> 0~100)
    return ((avgSimilarity + 1) / 2) * 100;
  }

  /// 기본 이미지 품질 설정
  Future<void> setDefaultImageQuality(ImageQuality quality) async {
    imageQuality = quality;
    await _prefs?.setString('imageQuality', quality.toString());
    notifyListeners();
  }

  /// 분석 완료된 좋아요 갤러리 개수
  int get analyzedFavoriteCount {
    return favorite.where((id) => galleryEmbeddings.containsKey(id)).length;
  }
}
