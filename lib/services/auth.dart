import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hitomiviewer/constants/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences? _prefs;

class Tokens {
  final String accessToken;
  final String refreshToken;

  Tokens({required this.accessToken, required this.refreshToken});

  factory Tokens.fromJson(Map<String, dynamic> json) {
    return Tokens(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
    );
  }
}

Future<Tokens> signin(String id, String password) async {
  try {
    final response = await http.post(Uri.https(API_HOST, '/api/auth/signin'),
        body: json.encode({
          'id': id,
          'password': password,
        }));

    if (response.statusCode == 200) {
      Tokens tokens = Tokens.fromJson(json.decode(response.body));
      _prefs ??= await SharedPreferences.getInstance();
      _prefs?.setString('refreshToken', tokens.refreshToken);

      return tokens;
    } else if (response.statusCode == 401) {
      throw Exception('Invalid ID or Password');
    } else {
      debugPrint('  - 응답 본문 전체:\n${response.body}');
      throw Exception('Failed to sign in (Status ${response.statusCode})');
    }
  } catch (e, stackTrace) {
    debugPrint('❌ signin 에러 발생:');
    debugPrint('  - ID: $id');
    debugPrint('  - 에러: $e');
    debugPrint('  - 스택 트레이스: $stackTrace');
    rethrow;
  }
}

Future<Tokens> signup(String id, String password) async {
  try {
    final response =
        await http.post(Uri.https(API_HOST, '/api/auth/signup'), body: {
      'id': id,
      'password': password,
    });

    if (response.statusCode == 200) {
      Tokens tokens = Tokens.fromJson(json.decode(response.body));
      _prefs ??= await SharedPreferences.getInstance();
      _prefs?.setString('refreshToken', tokens.refreshToken);

      return tokens;
    } else if (response.statusCode == 401) {
      throw Exception('Invalid ID or Password');
    } else {
      debugPrint('  - 응답 본문 전체:\n${response.body}');
      throw Exception('Failed to signup (Status ${response.statusCode})');
    }
  } catch (e, stackTrace) {
    debugPrint('❌ signup 에러 발생:');
    debugPrint('  - ID: $id');
    debugPrint('  - 에러: $e');
    debugPrint('  - 스택 트레이스: $stackTrace');
    rethrow;
  }
}

Future<String> refresh(String refreshToken) async {
  try {
    final response = await http.post(Uri.https(API_HOST, '/api/auth/refresh'),
        body: json.encode({'refreshToken': refreshToken}));

    if (response.statusCode == 200) {
      return response.body;
    } else if (response.statusCode == 401) {
      throw Exception('Invalid refresh token');
    } else {
      debugPrint('  - 응답 본문 전체:\n${response.body}');
      throw Exception('Failed to refresh token (Status ${response.statusCode})');
    }
  } catch (e, stackTrace) {
    debugPrint('❌ refresh 에러 발생:');
    debugPrint('  - 에러: $e');
    debugPrint('  - 스택 트레이스: $stackTrace');
    rethrow;
  }
}

class UserInfo {
  final String? id;
  final String? name;
  final String? email;
  final String? avatar;

  UserInfo(
      {required this.id,
      required this.name,
      required this.email,
      required this.avatar});

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatar: json['avatar'],
    );
  }
}

Future<UserInfo> getUserInfo(String accessToken) async {
  try {
    final response = await http.get(Uri.https(API_HOST, '/api/auth'), headers: {
      'Authorization': "Bearer $accessToken",
    });

    if (response.statusCode == 200) {
      return UserInfo.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Access token expired');
    } else {
      debugPrint('  - 응답 본문 전체:\n${response.body}');
      throw Exception('Failed to get user info (Status ${response.statusCode})');
    }
  } catch (e, stackTrace) {
    debugPrint('❌ getUserInfo 에러 발생:');
    debugPrint('  - 에러: $e');
    debugPrint('  - 스택 트레이스: $stackTrace');
    rethrow;
  }
}
