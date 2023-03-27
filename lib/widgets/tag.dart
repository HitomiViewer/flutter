import 'dart:ffi';

import 'package:flutter/material.dart';

class TagData {
  final String tag;
  final String type;

  Color get color {
    switch (type) {
      case 'female':
        return const Color(0xFFFF6D6D);
      case 'male':
        return const Color(0xFF4195F4);
      default:
        return Colors.grey[400]!;
    }
  }

  const TagData({required this.tag, required this.type});

  factory TagData.fromJson(Map<String, dynamic> json) {
    return TagData(
      tag: json['tag'] as String,
      type: json['female'] == 1
          ? 'female'
          : json['male'] == 1
              ? 'male'
              : 'tag',
    );
  }
}

class Tag extends StatelessWidget {
  final TagData tag;

  const Tag({Key? key, required this.tag}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tag.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tag.tag,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
        ),
      ),
    );
  }
}
