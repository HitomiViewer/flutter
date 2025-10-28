import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:hitomiviewer/services/image_embedding.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app_router.gr.dart';
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
  final embeddingService = ImageEmbeddingService();

  @override
  void initState() {
    super.initState();
    // PE-Core 모델은 앱 시작 시 초기화됨
  }

  void _findSimilarImages(BuildContext context) async {
    final store = Provider.of<Store>(context, listen: false);
    final currentId = int.parse(widget.detail['id'].toString());

    // 현재 갤러리의 임베딩이 있는지 확인
    if (!store.galleryEmbeddings.containsKey(currentId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이 갤러리는 아직 분석되지 않았습니다.\n배치 분석을 먼저 실행해주세요.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('유사한 이미지 찾는 중...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      debugPrint('🔍 유사 이미지 검색 시작: 갤러리 $currentId');
      
      final queryEmbedding = store.galleryEmbeddings[currentId]!;

      // 유사한 이미지 찾기 (현재 이미지 제외)
      final otherEmbeddings =
          Map<int, List<double>>.from(store.galleryEmbeddings);
      otherEmbeddings.remove(currentId);

      debugPrint('  - 검색 대상: ${otherEmbeddings.length}개 갤러리');

      final results = embeddingService.findSimilarImages(
        queryEmbedding,
        otherEmbeddings,
        topK: 50,
        minSimilarity: 0.5,
      );

      debugPrint('✅ 유사 이미지 검색 완료: ${results.length}개 발견');

      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('유사한 이미지를 찾지 못했습니다.')),
        );
        return;
      }

      // 결과 다이얼로그 표시
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.image_search, color: Colors.purple),
                    const SizedBox(width: 8),
                    const Text(
                      '유사한 이미지',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                Text('${results.length}개 발견'),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final result = results[index];
                      return Stack(
                        children: [
                          Preview(
                            key: Key(result.id.toString()),
                            id: result.id,
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: result.similarity > 0.8
                                    ? Colors.green
                                    : result.similarity > 0.7
                                        ? Colors.orange
                                        : Colors.grey,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${(result.similarity * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ 유사 이미지 검색 에러:');
      debugPrint('  - 갤러리 ID: $currentId');
      debugPrint('  - 에러: $e');
      debugPrint('  - 스택 트레이스: $stackTrace');
      
      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류 발생: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

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
          // AI 분석 버튼 (모델이 로드된 경우에만 표시)
          if (embeddingService.isModelReady)
            FloatingActionButton.small(
              heroTag: null,
              child: const Icon(Icons.analytics),
              onPressed: () {
                context.router.push(GalleryAnalysisRoute(
                  id: int.parse(widget.detail['id'].toString()),
                ));
              },
            ),
          // 유사 이미지 찾기 버튼
          if (embeddingService.isModelReady)
            FloatingActionButton.small(
              heroTag: null,
              child: const Icon(Icons.image_search),
              backgroundColor: Colors.purple,
              onPressed: () => _findSimilarImages(context),
            ),
          FloatingActionButton.small(
            heroTag: null,
            child: const Icon(Icons.share),
            onPressed: () {
              try {
                Share.share(
                    'https://hitomiviewer.pages.dev/#/hitomi/${widget.detail['id']}');
              } catch (e, stackTrace) {
                debugPrint('⚠️  공유 실패, 클립보드로 복사:');
                debugPrint('  - 에러: $e');
                debugPrint('  - 스택 트레이스: $stackTrace');
                
                Clipboard.setData(
                  ClipboardData(
                    text:
                        'https://hitomiviewer.pages.dev/#/hitomi/${widget.detail['id']}',
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
