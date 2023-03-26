import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/preview.dart';

class HitomiScreenArguments {
  final String? query;

  HitomiScreenArguments({this.query});
}

class HitomiScreen extends StatefulWidget {
  const HitomiScreen({Key? key}) : super(key: key);

  @override
  State<HitomiScreen> createState() => _HitomiScreenState();
}

class _HitomiScreenState extends State<HitomiScreen> {
  late Future<List<int>> galleries;
  late HitomiScreenArguments args;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    args = ModalRoute.of(context)!.settings.arguments as HitomiScreenArguments;
    if (args.query == null || args.query == '') {
      galleries = fetchPost();
    } else {
      galleries = searchGallery(args.query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hitomi'),
      ),
      body: Center(
        child: FutureBuilder(
          future: galleries,
          builder: (context, AsyncSnapshot<List<int>> snapshot) {
            if (snapshot.hasData) {
              return (ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return Preview(id: snapshot.data![index]);
                },
              ));
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}

Future<List<int>> fetchPost() async {
  final response = await http.get(Uri.https('api.toshu.me', ''));

  if (response.statusCode == 200) {
    // 만약 서버가 OK 응답을 반환하면, JSON을 파싱합니다.
    return List.castFrom<dynamic, int>(json.decode(response.body));
  } else {
    // 만약 응답이 OK가 아니면, 에러를 던집니다.
    throw Exception('Failed to load post');
  }
}

Future<List<int>> searchGallery(query) async {
  final response = await http.get(Uri.https('api.toshu.me', '/search', {
    'query': query,
  }));

  if (response.statusCode == 200) {
    // 만약 서버가 OK 응답을 반환하면, JSON을 파싱합니다.
    return List.castFrom<dynamic, int>(json.decode(response.body));
  } else {
    // 만약 응답이 OK가 아니면, 에러를 던집니다.
    throw Exception('Failed to load post');
  }
}

class HitomiDetailArguments {
  final int id;

  HitomiDetailArguments({required this.id});
}

class HitomiDetailScreen extends StatefulWidget {
  const HitomiDetailScreen({Key? key}) : super(key: key);

  @override
  State<HitomiDetailScreen> createState() => _HitomiDetailScreenState();
}

class _HitomiDetailScreenState extends State<HitomiDetailScreen> {
  late Future<Map<String, dynamic>> detail;
  late HitomiDetailArguments args;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    args = ModalRoute.of(context)!.settings.arguments as HitomiDetailArguments;
    detail = fetchDetail(args.id.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: FutureBuilder(
        future: detail,
        builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.hasData) {
            return Text(snapshot.data!['title']);
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }
          return const Text('Loading...');
        },
      )),
      body: FutureBuilder(
        future: detail,
        builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.hasData) {
            return PageView(
              children: [
                for (var i = 0; i < snapshot.data!['files'].length; i++)
                  Stack(
                    children: [
                      Center(
                        child: Image.network(
                            'https://api.toshu.me/images/webp/${snapshot.data!['files'][i]['hash']}',
                            loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }, errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text('Error'),
                          );
                        }),
                      ),
                      Positioned(
                          left: 0,
                          bottom: 0,
                          child: Text(
                              '${i + 1}/${snapshot.data!['files'].length}')),
                    ],
                  ),
              ],
            );
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }
          return const CircularProgressIndicator();
        },
      ),
    );
  }
}
