import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hitomiviewer/screens/hitomi.dart';
import 'package:hitomiviewer/widgets/tag.dart';
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
          return GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/hitomi/detail',
                    arguments: HitomiDetailArguments(id: widget.id));
              },
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: const Color(0xFFF3F2F1),
                ),
                child: Row(children: [
                  Container(
                      // width: 100, height: auto
                      constraints: const BoxConstraints.expand(width: 100),
                      color: Colors.white,
                      child: CachedNetworkImage(
                        imageUrl:
                            'https://api.toshu.me/images/preview/${snapshot.data!['files'][0]['hash']}',
                        imageBuilder: (context, imageProvider) => Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      )),
                  Flexible(
                    flex: 1,
                    child: Container(
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints.expand(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Flexible(
                                  fit: FlexFit.tight,
                                  child: Text(snapshot.data!['title'],
                                      softWrap: false,
                                      overflow: TextOverflow.fade,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          fontFamily: 'Pretendard'))),
                              const SizedBox(width: 10),
                              Text(
                                  snapshot.data!['date']
                                      .toString()
                                      .split(' ')[0],
                                  style: const TextStyle(
                                      color: Color(0xFFBBBBBB),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 10)),
                            ]),
                            const SizedBox(height: 10),
                            Flexible(
                                fit: FlexFit.tight,
                                child: Wrap(
                                  clipBehavior: Clip.antiAliasWithSaveLayer,
                                  runSpacing: 2,
                                  spacing: 2,
                                  children: [
                                    for (var tag
                                        in snapshot.data!['tags'] ?? [])
                                      Tag(tag: TagData.fromJson(tag)),
                                  ],
                                )),
                          ],
                        )),
                  ),
                ]),
              ));
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }
        return const LinearProgressIndicator(
          minHeight: 100,
        );
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
