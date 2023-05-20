import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hitomiviewer/api/hitomi.dart';
import 'package:hitomiviewer/widgets/tag.dart';

import '../screens/hitomi/detail.dart';
import '../screens/hitomi/reader.dart';

class Preview extends StatefulWidget {
  final int id;

  const Preview({Key? key, required this.id}) : super(key: key);

  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  bool get isDarkMode => Theme.of(context).brightness == Brightness.dark;
  Color get backgroundColor =>
      isDarkMode ? const Color(0xFF1C1C1C) : const Color(0xFFF3F2F1);
  Color get imageBackgroundColor => isDarkMode
      ? Theme.of(context).colorScheme.surface
      : Theme.of(context).colorScheme.surface;

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
                    arguments: HitomiReaderArguments(id: widget.id));
              },
              onLongPress: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: HitomiDetailScreen(
                      detail: snapshot.data!,
                    ),
                  ),
                );
              },
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: backgroundColor,
                ),
                child: Row(children: [
                  GestureDetector(
                    onLongPress: () => showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        child: CachedNetworkImage(
                          imageUrl:
                              'https://api.toshu.me/images/preview/${snapshot.data!['files'][0]['hash']}',
                        ),
                      ),
                    ),
                    child: Container(
                      // width: 100, height: auto
                      constraints: const BoxConstraints.expand(width: 100),
                      color: imageBackgroundColor,
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
                      ),
                    ),
                  ),
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
