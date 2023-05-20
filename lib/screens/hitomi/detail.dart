import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../widgets/preview.dart';
import '../../widgets/tag.dart';

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
                                  clipBehavior: Clip.antiAliasWithSaveLayer,
                                  runSpacing: 2,
                                  spacing: 2,
                                  children: [
                                    for (var tag in widget.detail['tags'] ?? [])
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
                itemCount: widget.detail['related'].length,
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
