import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hitomiviewer/services/hitomi.dart';
import 'package:hitomiviewer/services/image_embedding.dart';
import 'package:hitomiviewer/widgets/tag.dart';
import 'package:provider/provider.dart';

import '../constants/api.dart';
import '../screens/hitomi/detail.dart';
import '../store.dart';

class Preview extends StatefulWidget {
  final int id;
  final bool showRecommendationBadge;

  const Preview({
    Key? key,
    required this.id,
    this.showRecommendationBadge = false,
  }) : super(key: key);

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
  Widget build(BuildContext ctx) {
    return FutureBuilder(
      future: detail,
      builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.hasData) {
          bool blocked = checkBlocked(ctx, snapshot.data!['tags'] ?? []);
          return GestureDetector(
              onTap: () {
                context.read<Store>().addRecent(widget.id);
                logId(widget.id.toString());
                context.router.pushNamed('/hitomi/${widget.id}');
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
                              'https://$API_HOST/api/hitomi/images/preview/${snapshot.data!['files'][0]['hash']}.webp',
                          errorWidget: (context, url, error) => Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                    size: 64,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '이미지를 불러올 수 없습니다',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    child: Container(
                      // width: 100, height: auto
                      constraints: const BoxConstraints.expand(width: 100),
                      color: imageBackgroundColor,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                            sigmaX: 5, sigmaY: 5, tileMode: TileMode.decal),
                        enabled: blocked,
                        child: CachedNetworkImage(
                          imageUrl:
                              'https://$API_HOST/api/hitomi/images/preview/${snapshot.data!['files'][0]['hash']}.webp',
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
                          errorWidget: (context, url, error) => Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: imageBackgroundColor,
                            ),
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 40,
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
                              // 추천도 배지
                              _buildRecommendationBadge(context, widget.id),
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

  Widget _buildRecommendationBadge(BuildContext context, int galleryId) {
    // 🚀 플래그가 false면 표시하지 않음 (추천 탭이 아님)
    if (!widget.showRecommendationBadge) {
      return const SizedBox.shrink();
    }

    final store = context.watch<Store>();
    final embeddingService = ImageEmbeddingService();

    // 모델이 준비되지 않았거나 즐겨찾기가 비어있으면 표시하지 않음
    if (!embeddingService.isModelReady || store.galleryEmbeddings.isEmpty) {
      return const SizedBox.shrink();
    }

    // 즐겨찾기 중에 임베딩된 갤러리가 없으면 표시 안 함
    final hasFavoriteEmbeddings = store.favorite.any(
      (favId) => store.galleryEmbeddings.containsKey(favId),
    );
    if (!hasFavoriteEmbeddings) {
      return const SizedBox.shrink();
    }

    // 캐시된 추천도가 있으면 바로 표시
    final cachedScore = store.calculateRecommendationScore(galleryId);
    if (cachedScore != null) {
      return _buildScoreBadge(cachedScore);
    }

    // 🚀 캐시가 없으면 비동기로 계산 (큐로 관리되어 동시 실행 제한됨)
    return FutureBuilder<double>(
      future: _calculateAndCacheScore(context, galleryId),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data! > 0) {
          return _buildScoreBadge(snapshot.data!);
        }
        // 로딩 중이거나 실패 시 표시하지 않음
        return const SizedBox.shrink();
      },
    );
  }

  Future<double> _calculateAndCacheScore(
      BuildContext context, int galleryId) async {
    final store = Provider.of<Store>(context, listen: false);
    final embeddingService = ImageEmbeddingService();

    try {
      // 썸네일 URL 생성 (detail에서 가져와야 함)
      final detailSnapshot = await detail;
      if (detailSnapshot['files'] == null || detailSnapshot['files'].isEmpty) {
        return 0.0;
      }

      final thumbnailUrl =
          'https://$API_HOST/api/hitomi/images/preview/${detailSnapshot['files'][0]['hash']}.webp';

      // 즐겨찾기 갤러리의 임베딩만 사용
      final favoriteEmbeddings = <int, List<double>>{};
      for (var favId in store.favorite) {
        if (store.galleryEmbeddings.containsKey(favId)) {
          favoriteEmbeddings[favId] = store.galleryEmbeddings[favId]!;
        }
      }

      if (favoriteEmbeddings.isEmpty) {
        return 0.0;
      }

      // 추천도 계산
      final score = await embeddingService.calculateRecommendationScore(
        thumbnailUrl,
        favoriteEmbeddings,
      );

      // 캐시에 저장
      store.saveRecommendationScore(galleryId, score);

      return score * 100; // 0-100 범위로 변환
    } catch (e) {
      debugPrint('추천도 계산 실패 (Gallery $galleryId): $e');
      return 0.0;
    }
  }

  Widget _buildScoreBadge(double score) {
    // 모든 점수를 표시 (색상으로 구분)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getScoreColor(score),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 10, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            '${score.toInt()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    // 점수가 낮아졌으므로 기준도 하향 조정
    if (score >= 70) {
      return Colors.green; // 70+ : 매우 추천!
    } else if (score >= 50) {
      return Colors.orange; // 50-69 : 괜찮은 추천
    } else if (score >= 30) {
      return Colors.grey; // 30-49 : 약한 추천
    } else {
      return Colors.blueGrey; // 30 미만 : 매우 약한 추천
    }
  }
}

bool checkBlocked(BuildContext context, List<dynamic> tags) {
  for (var tag in tags) {
    String tagName = (tag['male'].toString() == "1" ? "male:" : "") +
        (tag['female'].toString() == "1" ? "female:" : "") +
        tag['tag'];
    if (context.read<Store>().blacklist.contains(tagName)) {
      return true;
    }
  }
  return false;
}
