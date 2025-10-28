import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:tuple/tuple.dart';

import '../constants/api.dart';

Future<Map<String, dynamic>> fetchDetail(String id) async {
  try {
    final url = Uri.https(API_HOST, '/api/hitomi/detail/$id');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // 만약 서버가 OK 응답을 반환하면, JSON을 파싱합니다.
      try {
        return json.decode(utf8.decode(response.bodyBytes));
      } catch (e, stackTrace) {
        debugPrint('❌ fetchDetail JSON 파싱 에러:');
        debugPrint('  - 갤러리 ID: $id');
        debugPrint('  - 응답 길이: ${response.bodyBytes.length} bytes');
        debugPrint('  - 에러: $e');
        debugPrint('  - 스택 트레이스: $stackTrace');
        rethrow;
      }
    } else {
      // 만약 응답이 OK가 아니면, 에러를 던집니다.
      debugPrint('  - 응답 본문 전체:\n${response.body}');
      throw Exception('Failed to fetch detail for gallery $id (Status ${response.statusCode})');
    }
  } catch (e, stackTrace) {
    debugPrint('❌ fetchDetail 에러 발생:');
    debugPrint('  - 갤러리 ID: $id');
    debugPrint('  - 에러: $e');
    debugPrint('  - 스택 트레이스: $stackTrace');
    rethrow;
  }
}

Future<Tuple2<List<int>, DateTime?>> fetchPost([String? language]) async {
  try {
    final response = await http.get(Uri.https(API_HOST, '/api/hitomi', {
      language == null ? '' : 'language': language,
    }));

    if (response.statusCode == 200) {
      // 만약 서버가 OK 응답을 반환하면, JSON을 파싱합니다.
      // HTTP Date: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Date
      try {
        String? date = response.headers['generated-date'];
        return Tuple2<List<int>, DateTime?>(
          List.castFrom<dynamic, int>(json.decode(response.body)),
          date == null ? null : HttpDate.parse(date),
        );
      } catch (e, stackTrace) {
        debugPrint('❌ fetchPost JSON 파싱 에러:');
        debugPrint('  - 언어: ${language ?? "all"}');
        debugPrint('  - 응답 본문: ${response.body}');
        debugPrint('  - 에러: $e');
        debugPrint('  - 스택 트레이스: $stackTrace');
        rethrow;
      }
    } else {
      // 만약 응답이 OK가 아니면, 에러를 던집니다.
      debugPrint('  - 응답 본문 전체:\n${response.body}');
      throw Exception('Failed to fetch posts (language: ${language ?? "all"}, Status ${response.statusCode})');
    }
  } catch (e, stackTrace) {
    debugPrint('❌ fetchPost 에러 발생:');
    debugPrint('  - 언어: ${language ?? "all"}');
    debugPrint('  - 에러: $e');
    debugPrint('  - 스택 트레이스: $stackTrace');
    rethrow;
  }
}

Future<Tuple2<List<int>, DateTime?>> searchGallery(query,
    [String? language]) async {
  try {
    final response = await http.get(Uri.https(API_HOST, '/api/hitomi', {
      'query': query,
      language == null ? '' : 'language': language,
    }));

    if (response.statusCode == 200) {
      // 만약 서버가 OK 응답을 반환하면, JSON을 파싱합니다.
      try {
        String? date = response.headers['generated-date'];
        return Tuple2<List<int>, DateTime?>(
          List.castFrom<dynamic, int>(json.decode(response.body)),
          date == null ? null : HttpDate.parse(date),
        );
      } catch (e, stackTrace) {
        debugPrint('❌ searchGallery JSON 파싱 에러:');
        debugPrint('  - 쿼리: $query');
        debugPrint('  - 언어: ${language ?? "all"}');
        debugPrint('  - 응답 본문: ${response.body}');
        debugPrint('  - 에러: $e');
        debugPrint('  - 스택 트레이스: $stackTrace');
        rethrow;
      }
    } else {
      // 만약 응답이 OK가 아니면, 에러를 던집니다.
      debugPrint('  - 응답 본문 전체:\n${response.body}');
      throw Exception('Failed to search gallery (query: $query, language: ${language ?? "all"}, Status ${response.statusCode})');
    }
  } catch (e, stackTrace) {
    debugPrint('❌ searchGallery 에러 발생:');
    debugPrint('  - 쿼리: $query');
    debugPrint('  - 언어: ${language ?? "all"}');
    debugPrint('  - 에러: $e');
    debugPrint('  - 스택 트레이스: $stackTrace');
    rethrow;
  }
}

class TagInfo {
  final String tag;
  final int count;
  final String url;
  final String ns;

  TagInfo(
      {required this.tag,
      required this.count,
      required this.url,
      required this.ns});

  factory TagInfo.fromJson(Map<String, dynamic> json) {
    return TagInfo(
      tag: json['tag'],
      count: json['count'],
      url: json['url'],
      ns: json['ns'],
    );
  }

  @override
  String toString() {
    return '$ns:${tag.replaceAll(' ', '_')}';
  }
}

Future<List<TagInfo>> autocomplete(query) async {
  try {
    final response = await http.get(Uri.https(API_HOST, '/api/hitomi/suggest', {
      'query': query,
    }));

    if (response.statusCode == 200) {
      print(response.body);
      // 만약 서버가 OK 응답을 반환하면, JSON을 파싱합니다.
      try {
        return json
            .decode(
              utf8.decode(response.bodyBytes),
            )
            .map<TagInfo>((e) => TagInfo.fromJson(e))
            .toList();
      } catch (e, stackTrace) {
        debugPrint('❌ autocomplete JSON 파싱 에러:');
        debugPrint('  - 쿼리: $query');
        debugPrint('  - 응답 길이: ${response.bodyBytes.length} bytes');
        debugPrint('  - 에러: $e');
        debugPrint('  - 스택 트레이스: $stackTrace');
        rethrow;
      }
    } else {
      // 만약 응답이 OK가 아니면, 에러를 던집니다.
      debugPrint('  - 응답 본문 전체:\n${response.body}');
      throw Exception('Failed to autocomplete (query: $query, Status ${response.statusCode})');
    }
  } catch (e, stackTrace) {
    debugPrint('❌ autocomplete 에러 발생:');
    debugPrint('  - 쿼리: $query');
    debugPrint('  - 에러: $e');
    debugPrint('  - 스택 트레이스: $stackTrace');
    rethrow;
  }
}

Future<void> logId(String id) async {
  // await http.get(Uri.https(API_HOST, '/log/$id'));
}
