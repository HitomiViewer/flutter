import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api.dart';

Future<Map<String, dynamic>> fetchDetail(String id) async {
  final response =
      await http.get(Uri.https(API_HOST, '/api/hitomi/detail/$id'));

  if (response.statusCode == 200) {
    // 만약 서버가 OK 응답을 반환하면, JSON을 파싱합니다.
    return json.decode(response.body);
  } else {
    // 만약 응답이 OK가 아니면, 에러를 던집니다.
    throw Exception('Failed to load post');
  }
}

Future<List<int>> fetchPost([String? language]) async {
  final response = await http.get(Uri.https(API_HOST, '/api/hitomi', {
    language == null ? '' : 'language': language,
  }));

  if (response.statusCode == 200) {
    // 만약 서버가 OK 응답을 반환하면, JSON을 파싱합니다.
    return List.castFrom<dynamic, int>(json.decode(response.body));
  } else {
    // 만약 응답이 OK가 아니면, 에러를 던집니다.
    throw Exception('Failed to load post');
  }
}

Future<List<int>> searchGallery(query, [String? language]) async {
  final response = await http.get(Uri.https(API_HOST, '/api/hitomi', {
    'query': query,
    language == null ? '' : 'language': language,
  }));

  if (response.statusCode == 200) {
    // 만약 서버가 OK 응답을 반환하면, JSON을 파싱합니다.
    return List.castFrom<dynamic, int>(json.decode(response.body));
  } else {
    // 만약 응답이 OK가 아니면, 에러를 던집니다.
    throw Exception('Failed to load post');
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
  final response = await http.get(Uri.https(API_HOST, '/api/hitomi/suggest', {
    'query': query,
  }));

  if (response.statusCode == 200) {
    print(response.body);
    // 만약 서버가 OK 응답을 반환하면, JSON을 파싱합니다.
    return json
        .decode(response.body)
        .map<TagInfo>((e) => TagInfo.fromJson(e))
        .toList();
  } else {
    // 만약 응답이 OK가 아니면, 에러를 던집니다.
    throw Exception('Failed to load post');
  }
}

Future<void> logId(String id) async {
  // await http.get(Uri.https(API_HOST, '/log/$id'));
}
