import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../constants/api.dart';
import '../../store.dart';
import '../../widgets/preview.dart';
import '../../widgets/tag.dart';
import 'reader.dart';

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
                width: constraints.maxWidth,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: constraints.maxHeight,
                            maxWidth: constraints.maxWidth / 2,
                          ),
                          child: GestureDetector(
                            child: CachedNetworkImage(
                              imageUrl:
                                  'https://$API_HOST/api/hitomi/images/${widget.detail['files'][0]['hash']}.webp',
                            ),
                            onTap: () => showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                child: HitomiReaderScreen(
                                  id: int.parse(widget.detail['id'].toString()),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(widget.detail['title']),
                              Text((widget.detail['artists'] ?? [])
                                  .map((x) => x['artist'])
                                  .join(', ')),
                              Table(
                                children: [
                                  TableRow(children: [
                                    const Text('Group'),
                                    Text((widget.detail['groups'] ?? [])
                                        .map((x) => x['group'])
                                        .join(', ')),
                                  ]),
                                  TableRow(children: [
                                    const Text('Type'),
                                    Text(widget.detail['type']),
                                  ]),
                                  TableRow(children: [
                                    const Text('Language'),
                                    Text(
                                      "${widget.detail['language']} (${widget.detail['language_localname']})",
                                    ),
                                  ]),
                                  TableRow(children: [
                                    const Text('Series'),
                                    Text((widget.detail['parodys'] ?? [])
                                        .map((x) => x['parody'])
                                        .join(', ')),
                                  ]),
                                  TableRow(children: [
                                    const Text('Characters'),
                                    Text((widget.detail['characters'] ?? [])
                                        .map((x) => x['character'])
                                        .join(', ')),
                                  ]),
                                  TableRow(children: [
                                    const Text('Tags'),
                                    Wrap(
                                      runSpacing: 2,
                                      spacing: 2,
                                      children: [
                                        for (var tag
                                            in widget.detail['tags'] ?? [])
                                          Tag(tag: TagData.fromJson(tag)),
                                      ],
                                    ),
                                  ]),
                                  TableRow(children: [
                                    const Text('Uploaded'),
                                    Text(widget.detail['date']),
                                  ]),
                                  TableRow(children: [
                                    const Text('Pages'),
                                    Text(widget.detail['files'].length
                                        .toString()),
                                  ]),
                                ],
                              ),
                              IconButton(
                                icon: context.read<Store>().containsFavorite(
                                        int.parse(
                                            widget.detail['id'].toString()))
                                    ? const Icon(Icons.favorite)
                                    : const Icon(Icons.favorite_border),
                                onPressed: () {
                                  if (context.read<Store>().containsFavorite(
                                      int.parse(
                                          widget.detail['id'].toString()))) {
                                    context.read<Store>().removeFavorite(
                                        int.parse(
                                            widget.detail['id'].toString()));
                                  } else {
                                    context.read<Store>().addFavorite(int.parse(
                                        widget.detail['id'].toString()));
                                  }
                                  setState(() {});
                                },
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                itemCount: widget.detail['related'].length,
                itemBuilder: (context, index) {
                  return Preview(id: widget.detail['related'][index]);
                },
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                physics: const NeverScrollableScrollPhysics(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        type: ExpandableFabType.up,
        distance: 60.0,
        overlayStyle: ExpandableFabOverlayStyle(
          color: Colors.black.withOpacity(0.5),
        ),
        children: [
          FloatingActionButton.small(
            heroTag: null,
            child: const Icon(Icons.share),
            onPressed: () {
              try {
                Share.share('https://hitomiviewer.pages.dev/#/hitomi/${widget.detail['id']}');
              } catch (e) {
                Clipboard.setData(
                  ClipboardData(
                    text: 'https://hitomiviewer.pages.dev/#/hitomi/${widget.detail['id']}',
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                  ),
                );
              }
            },
          ),
          FloatingActionButton.small(
            heroTag: null,
            child: context
                    .read<Store>()
                    .containsFavorite(int.parse(widget.detail['id'].toString()))
                ? const Icon(Icons.favorite)
                : const Icon(Icons.favorite_border),
            onPressed: () {
              context
                  .read<Store>()
                  .toggleFavorite(int.parse(widget.detail['id'].toString()));
              setState(() {});
            },
          ),
          FloatingActionButton.small(
            heroTag: null,
            child: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(
                ClipboardData(
                  text: widget.detail['id'].toString(),
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied to clipboard'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
