import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hitomiviewer/services/auth.dart';
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

  // ===== 이미지 임베딩 기능 =====

  // 이미지 분석 결과 저장: galleryId -> { 'text': String, 'quality': String, 'timestamp': int }
  var imageAnalysis = <int, Map<String, dynamic>>{};

  // 갤러리 임베딩 저장: galleryId -> embedding vector
  var galleryEmbeddings = <int, List<double>>{};

  // 각 임베딩에 사용된 모델 정보: galleryId -> model name
  var embeddingModels = <int, String>{};

  // 추천도 캐시: galleryId -> 추천도(0-100)
  var recommendationScores = <int, double>{};

  /// 추천도 계산 (캐시 활용)
  double? calculateRecommendationScore(int galleryId) {
    // 이미 계산된 경우 캐시 반환
    if (recommendationScores.containsKey(galleryId)) {
      return recommendationScores[galleryId];
    }
    return null; // 아직 계산되지 않음
  }

  /// 추천도 저장
  void saveRecommendationScore(int galleryId, double score) {
    recommendationScores[galleryId] = score * 100; // 0-1을 0-100으로 변환
    notifyListeners();
  }

  /// 추천도 캐시 초기화
  void clearRecommendationScores() {
    recommendationScores.clear();
    notifyListeners();
  }

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

    // 임베딩 모델 정보 로드
    final modelsStr = _prefs?.getString('embeddingModels');
    if (modelsStr != null && modelsStr.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = json.decode(modelsStr);
        embeddingModels = decoded.map((key, value) => MapEntry(
              int.parse(key),
              value.toString(),
            ));
      } catch (e) {
        debugPrint('임베딩 모델 정보 로드 실패: $e');
      }
    }
  }

  /// 이미지 분석 결과 저장
  Future<void> saveImageAnalysis(
    int galleryId,
    String analysis, {
    String? modelName,
  }) async {
    imageAnalysis[galleryId] = {
      'text': analysis,
      'model': modelName,
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
    List<double> embedding, {
    String? modelName,
  }) async {
    galleryEmbeddings[galleryId] = embedding;

    if (modelName != null) {
      embeddingModels[galleryId] = modelName;
    }

    // SharedPreferences에 저장
    final embeddingsJson = json.encode(galleryEmbeddings.map(
      (key, value) => MapEntry(key.toString(), value),
    ));
    await _prefs?.setString('galleryEmbeddings', embeddingsJson);

    final modelsJson = json.encode(embeddingModels.map(
      (key, value) => MapEntry(key.toString(), value),
    ));
    await _prefs?.setString('embeddingModels', modelsJson);

    notifyListeners();
  }

  /// 임베딩 삭제
  Future<void> clearEmbeddings() async {
    galleryEmbeddings.clear();
    embeddingModels.clear();
    await _prefs?.remove('galleryEmbeddings');
    await _prefs?.remove('embeddingModels');
    notifyListeners();
  }

  /// 분석 완료된 좋아요 갤러리 개수
  int get analyzedFavoriteCount {
    return favorite.where((id) => galleryEmbeddings.containsKey(id)).length;
  }
}
