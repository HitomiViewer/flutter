import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api.dart';

Future<List<int>> getFavorites(String accessToken) async {
  try {
    final response =
        await http.get(Uri.https(API_HOST, '/api/userdata'), headers: {
      'Authorization': "Bearer $accessToken",
    });

    if (response.statusCode == 200) {
      try {
        final decoded = json.decode(response.body);
        return List<int>.from(decoded['favorites']).toList();
      } catch (e, stackTrace) {
        debugPrint('❌ getFavorites JSON 파싱 에러:');
        debugPrint('  - 응답 본문: ${response.body}');
        debugPrint('  - 에러: $e');
        debugPrint('  - 스택 트레이스: $stackTrace');
        rethrow;
      }
    } else if (response.statusCode == 401) {
      throw Exception('Access token expired');
    } else {
      debugPrint('  - 응답 본문 전체:\n${response.body}');
      throw Exception('Failed to get favorites (Status ${response.statusCode})');
    }
  } catch (e, stackTrace) {
    debugPrint('❌ getFavorites 에러 발생:');
    debugPrint('  - 에러: $e');
    debugPrint('  - 스택 트레이스: $stackTrace');
    rethrow;
  }
}

Future<void> setFavorites(String accessToken, List<int> favorites) async {
  try {
    final response = await http.post(Uri.https(API_HOST, '/api/userdata'),
        headers: {
          'Authorization': "Bearer $accessToken",
          'Content-type': 'application/json',
        },
        body: json.encode({'favorites': favorites}));

    if (response.statusCode ~/ 100 == 2) {
      return;
    } else if (response.statusCode == 401) {
      throw Exception('Access token expired');
    } else {
      debugPrint('  - 응답 본문 전체:\n${response.body}');
      throw Exception('Failed to set favorites (Status ${response.statusCode})');
    }
  } catch (e, stackTrace) {
    debugPrint('❌ setFavorites 에러 발생:');
    debugPrint('  - 즐겨찾기 개수: ${favorites.length}');
    debugPrint('  - 에러: $e');
    debugPrint('  - 스택 트레이스: $stackTrace');
    rethrow;
  }
}
