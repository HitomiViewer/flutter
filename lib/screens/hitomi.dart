import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late HitomiScreenArguments? args;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    args = ModalRoute.of(context)!.settings.arguments as HitomiScreenArguments?;
    if (args?.query == null || args?.query == '') {
      galleries = fetchPost();
    } else {
      galleries = searchGallery(args?.query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            args?.query == null || args?.query == '' ? '추천' : '${args?.query}'),
      ),
      body: Center(
        child: FutureBuilder(
          future: galleries,
          builder: (context, AsyncSnapshot<List<int>> snapshot) {
            if (snapshot.hasData) {
              return (ListView.separated(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return Preview(id: snapshot.data![index]);
                },
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
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
    'language': 'korean',
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

  final PageController _controller = PageController();
  final FocusNode _focusNode = FocusNode();

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

  void _handleKeyEvent(RawKeyEvent event) {
    if (event.runtimeType == RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        setState(() {
          _controller.previousPage(
              duration: const Duration(milliseconds: 200), curve: Curves.ease);
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        setState(() {
          _controller.nextPage(
              duration: const Duration(milliseconds: 200), curve: Curves.ease);
        });
      }
    }
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
        body: RawKeyboardListener(
          autofocus: true,
          focusNode: _focusNode,
          onKey: _handleKeyEvent,
          child: FutureBuilder(
            future: detail,
            builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
              if (snapshot.hasData) {
                return PageView(
                  controller: _controller,
                  allowImplicitScrolling: true,
                  children: [
                    for (var i = 0; i < snapshot.data!['files'].length; i++)
                      Stack(
                        children: [
                          Center(
                            child: CachedNetworkImage(
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(),
                              imageUrl:
                                  'https://api.toshu.me/images/webp/${snapshot.data!['files'][i]['hash']}',
                            ),
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
                return Center(child: Text('${snapshot.error}'));
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
}
