import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hitomiviewer/api/hitomi.dart';

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
