import 'dart:convert';

import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchDetail(String id) async {
  final response = await http.get(Uri.https('api.toshu.me', '/detail/$id'));

  if (response.statusCode == 200) {
    // 만약 서버가 OK 응답을 반환하면, JSON을 파싱합니다.
    return json.decode(response.body);
  } else {
    // 만약 응답이 OK가 아니면, 에러를 던집니다.
    throw Exception('Failed to load post');
  }
}

Future<List<int>> fetchPost([String? language]) async {
  final response = await http.get(Uri.https('api.toshu.me', '', {
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
  final response = await http.get(Uri.https('api.toshu.me', '/search', {
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
