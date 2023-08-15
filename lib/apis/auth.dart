import 'dart:convert';

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
  final response =
      await http.post(Uri.https(API_HOST, '/auth/signin/app'), body: {
    'id': id,
    'password': password,
  });

  if (response.statusCode == 201) {
    Tokens tokens = Tokens.fromJson(json.decode(response.body));
    _prefs ??= await SharedPreferences.getInstance();
    _prefs?.setString('refreshToken', tokens.refreshToken);

    return tokens;
  } else if (response.statusCode == 401) {
    throw Exception('Invalid ID or Password');
  } else {
    throw Exception('Failed to sign in');
  }
}

Future<Tokens> signup(String id, String password) async {
  final response =
      await http.post(Uri.https(API_HOST, '/auth/signup/app'), body: {
    'id': id,
    'password': password,
  });

  if (response.statusCode == 201) {
    Tokens tokens = Tokens.fromJson(json.decode(response.body));
    _prefs ??= await SharedPreferences.getInstance();
    _prefs?.setString('refreshToken', tokens.refreshToken);

    return tokens;
  } else if (response.statusCode == 401) {
    throw Exception('Invalid ID or Password');
  } else {
    throw Exception('Failed to load post');
  }
}

Future<String> refresh(String refreshToken) async {
  final response = await http.post(Uri.https(API_HOST, '/auth/refresh/app'),
      body: {'refreshToken': refreshToken});

  if (response.statusCode == 201) {
    return response.body;
  } else if (response.statusCode == 401) {
    throw Exception('Invalid refresh token');
  } else {
    throw Exception('Failed to load post');
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
  final response = await http.get(Uri.https(API_HOST, '/auth'), headers: {
    'Authorization': "Bearer $accessToken",
  });

  if (response.statusCode == 200) {
    return UserInfo.fromJson(json.decode(response.body));
  } else if (response.statusCode == 401) {
    throw Exception('Access token expired');
  } else {
    throw Exception('Failed to load post');
  }
}
