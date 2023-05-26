import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hitomiviewer/screens/hitomi.dart';
import 'package:http/http.dart' as http;

class Preview extends StatefulWidget {
  final int id;

  const Preview({Key? key, required this.id}) : super(key: key);

  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  late Future<Map<String, dynamic>> detail;

  @override
  void initState() {
    super.initState();
    detail = fetchDetail(widget.id.toString());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: detail,
      builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.hasData) {
          ListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: 4),
              title: Text(snapshot.data!['title']),
              leading: Image.network(
                  'https://api.toshu.me/images/preview/${snapshot.data!['files'][0]['hash']}'),
              trailing: Text(snapshot.data!['language'] ?? 'N/A'),
              minLeadingWidth: 100,
              onTap: () {
                Navigator.pushNamed(context, '/hitomi/detail',
                    arguments: HitomiDetailArguments(id: widget.id));
              });
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(5),
            ),
          );
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }
        return const LinearProgressIndicator();
      },
    );
  }
}

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
