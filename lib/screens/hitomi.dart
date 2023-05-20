import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hitomiviewer/store.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../widgets/preview.dart';
import '../widgets/tag.dart';

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
      galleries = fetchPost(context.watch<Store>().language);
    } else {
      galleries = searchGallery(args?.query, context.watch<Store>().language);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            args?.query == null || args?.query == '' ? '추천' : '${args?.query}'),
        key: Key(context.watch<Store>().language),
      ),
      body: Center(
        child: FutureBuilder(
          key: Key(context.watch<Store>().language),
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

class HitomiReaderArguments {
  final int id;

  HitomiReaderArguments({required this.id});
}

class HitomiReaderScreen extends StatefulWidget {
  final int? id;
  final bool isFullScreen;
  const HitomiReaderScreen({Key? key, this.id, this.isFullScreen = false})
      : super(key: key);

  @override
  State<HitomiReaderScreen> createState() => _HitomiReaderScreenState();
}

class _HitomiReaderScreenState extends State<HitomiReaderScreen> {
  late Future<Map<String, dynamic>> detail;
  late HitomiReaderArguments? args;

  final PageController _controller = PageController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    args = ModalRoute.of(context)!.settings.arguments as HitomiReaderArguments?;
    detail = fetchDetail((args?.id ?? widget.id).toString());
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
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: widget.isFullScreen
            ? null
            : AppBar(
                title: FutureBuilder(
                  future: detail,
                  builder:
                      (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
                    if (snapshot.hasData) {
                      return Text(snapshot.data!['title']);
                    } else if (snapshot.hasError) {
                      return Text('${snapshot.error}');
                    }
                    return const Text('Loading...');
                  },
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.fullscreen),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return HitomiReaderScreen(
                                id: args?.id ?? widget.id,
                                isFullScreen: true,
                              );
                            },
                            fullscreenDialog: true,
                          ));
                    },
                  ),
                ],
              ),
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
                              filterQuality: FilterQuality.high,
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

class HitomiDetailScreen extends StatefulWidget {
  final Map<String, dynamic> detail;
  const HitomiDetailScreen({Key? key, required this.detail}) : super(key: key);

  @override
  State<HitomiDetailScreen> createState() => _HitomiDetailScreenState();
}

class _HitomiDetailScreenState extends State<HitomiDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.detail['title']),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: constraints.maxHeight,
                width: constraints.maxWidth,
                child: Row(
                  children: [
                    Flexible(
                      child: CachedNetworkImage(
                        imageUrl:
                            'https://api.toshu.me/images/webp/${widget.detail['files'][0]['hash']}',
                      ),
                    ),
                    Flexible(
                      child: Column(
                        children: [
                          Text(widget.detail['title']),
                          Text((widget.detail['artists'] ?? [])
                              .map((x) => x['artist'])
                              .join(', ')),
                          Table(
                            children: [
                              TableRow(children: [
                                Text('Group'),
                                Text((widget.detail['groups'] ?? [])
                                    .map((x) => x['group'])
                                    .join(', ')),
                              ]),
                              TableRow(children: [
                                Text('Type'),
                                Text(widget.detail['type']),
                              ]),
                              TableRow(children: [
                                Text('Language'),
                                Text(
                                  "${widget.detail['language']} (${widget.detail['language_localname']})",
                                ),
                              ]),
                              TableRow(children: [
                                Text('Series'),
                                Text((widget.detail['parodys'] ?? [])
                                    .map((x) => x['parody'])
                                    .join(', ')),
                              ]),
                              TableRow(children: [
                                Text('Characters'),
                                Text((widget.detail['characters'] ?? [])
                                    .map((x) => x['character'])
                                    .join(', ')),
                              ]),
                              TableRow(children: [
                                Text('Tags'),
                                Wrap(
                                  clipBehavior: Clip.antiAliasWithSaveLayer,
                                  runSpacing: 2,
                                  spacing: 2,
                                  children: [
                                    for (var tag
                                        in widget.detail!['tags'] ?? [])
                                      Tag(tag: TagData.fromJson(tag)),
                                  ],
                                ),
                              ]),
                              TableRow(children: [
                                Text('Uploaded'),
                                Text(widget.detail['date']),
                              ]),
                              TableRow(children: [
                                Text('Pages'),
                                Text(widget.detail['files'].length.toString()),
                              ]),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                itemCount: 2,
                itemBuilder: (context, index) {
                  return Preview(id: widget.detail['related'][index]);
                },
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
