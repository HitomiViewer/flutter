import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api.dart';

Future<List<int>> getFavorites(String accessToken) async {
  final response =
      await http.get(Uri.https(API_HOST, '/api/hitomi/favorite'), headers: {
    'Authorization': "Bearer $accessToken",
  });

  if (response.statusCode == 200) {
    return List<String>.from(json.decode(response.body)['favorites'])
        .map((e) => int.parse(e))
        .toList();
  } else if (response.statusCode == 401) {
    throw Exception('Access token expired');
  } else {
    throw Exception('Failed to load post');
  }
}

Future<void> setFavorites(String accessToken, List<int> favorites) async {
  final response = await http.post(Uri.https(API_HOST, '/api/hitomi/favorite'),
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
    throw Exception('Failed to request (status code: ${response.statusCode})');
  }
}
