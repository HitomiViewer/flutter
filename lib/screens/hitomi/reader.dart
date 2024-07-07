import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hitomiviewer/services/hitomi.dart';
import 'package:hitomiviewer/constants/api.dart';

class HitomiReaderArguments {
  final int id;

  HitomiReaderArguments({required this.id});
}

@RoutePage()
class HitomiReaderScreen extends StatefulWidget {
  final int? id;
  final bool isFullScreen;
  final int initialPage;
  const HitomiReaderScreen(
      {Key? key,
      @PathParam('id') required this.id,
      this.isFullScreen = false,
      this.initialPage = 0})
      : super(key: key);

  @override
  State<HitomiReaderScreen> createState() => _HitomiReaderScreenState();
}

class _HitomiReaderScreenState extends State<HitomiReaderScreen> {
  late Future<Map<String, dynamic>> detail;
  late HitomiReaderArguments? args;

  late final PageController _controller = PageController(
    initialPage: widget.initialPage,
  );

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
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
                              initialPage: _controller.page!.toInt(),
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
                                'https://$API_HOST/api/hitomi/images/${snapshot.data!['files'][i]['hash']}.webp',
                            filterQuality: FilterQuality.high,
                            memCacheHeight: MediaQuery.of(context)
                                .size
                                .height
                                .toInt(), // cache image with height of screen
                          ),
                        ),
                        Positioned(
                          top: 0,
                          child: SafeArea(
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: Center(
                                child: Text(
                                    '${i + 1}/${snapshot.data!['files'].length}'),
                              ),
                            ),
                          ),
                        ),
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
      ),
      floatingActionButton: FloatingActionButton(
        // move to page of input number
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Go to page'),
                content: TextField(
                  keyboardType: TextInputType.number,
                  onSubmitted: (value) {
                    setState(() {
                      _controller.jumpToPage(int.parse(value) - 1);
                    });
                    Navigator.pop(context);
                  },
                ),
              );
            },
          );
        },
        child: const Icon(Icons.search),
      ),
    );
  }

  @override
  void dispose() {
    if (widget.isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _focusNode.dispose();
    super.dispose();
  }
}
