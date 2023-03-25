import 'package:flutter/material.dart';

class Detail {
  final String id;
  final String title;
  final String type;
  final String language;

  Detail({
    required this.id,
    required this.title,
    required this.type,
    required this.language,
  });

  factory Detail.fromJson(Map<String, dynamic> json) {
    return Detail(
      id: json['id'],
      title: json['title'],
      type: json['type'],
      language: json['language'],
    );
  }
}
