import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hitomiviewer/constants/api.dart';
import 'package:hitomiviewer/services/image_embedding.dart';
import 'package:hitomiviewer/services/hitomi.dart';
import 'package:hitomiviewer/store.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

@RoutePage()
class GalleryAnalysisScreen extends StatefulWidget {
  final int id;

  const GalleryAnalysisScreen({Key? key, @PathParam('id') required this.id})
      : super(key: key);

  @override
  State<GalleryAnalysisScreen> createState() => _GalleryAnalysisScreenState();
}

class _GalleryAnalysisScreenState extends State<GalleryAnalysisScreen> {
  late Future<Map<String, dynamic>> detail;
  final embeddingService = ImageEmbeddingService();
  bool useThumbnail = true;

  // 이미지별 분석 상태
  Map<int, bool> analyzing = {};
  Map<int, bool> analyzed = {};
  Map<int, String?> analysisErrors = {};

  @override
  void initState() {
    super.initState();
    detail = fetchDetail(widget.id.toString());
    // PE-Core 모델은 앱 시작 시 초기화됨
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('갤러리 분석'),
        actions: [
          // 실패한 항목 재시도 버튼
          if (analysisErrors.values.where((e) => e != null).isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '실패한 항목 재시도',
              onPressed: _retryFailedImages,
            ),
          // 전체 분석 버튼
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _analyzeAll,
          ),
        ],
      ),
      body: FutureBuilder(
        future: detail,
        builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.hasData) {
            final files = snapshot.data!['files'] as List;
            return Column(
              children: [
                // 상단 정보 카드
                _buildInfoCard(snapshot.data!, files.length),
                // 이미지 그리드
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      return _buildImageCard(files[index], index);
                    },
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> data, int totalCount) {
    final analyzedCount = analyzed.values.where((a) => a == true).length;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['title'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text('총 $totalCount장'),
                  avatar: const Icon(Icons.image, size: 16),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text('분석 완료 $analyzedCount장'),
                  avatar: const Icon(Icons.check_circle, size: 16),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(useThumbnail ? '썸네일' : '원본'),
                  avatar: const Icon(Icons.image, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(Map<String, dynamic> file, int index) {
    final hash = file['hash'];
    final imageUrl = useThumbnail
        ? 'https://$API_HOST/api/hitomi/images/preview/$hash.webp'
        : 'https://$API_HOST/api/hitomi/images/$hash.webp';

    final isAnalyzing = analyzing[index] ?? false;
    final isAnalyzed = analyzed[index] ?? false;
    final error = analysisErrors[index];

    return GestureDetector(
      onTap: () {
        // 에러가 있으면 재시도, 아니면 분석
        if (error != null) {
          _retryImage(imageUrl, index);
        } else if (!isAnalyzing && !isAnalyzed) {
          _analyzeImage(imageUrl, index);
        }
      },
      child: Stack(
        children: [
          // 이미지
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isAnalyzed ? Colors.green : Colors.grey,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl:
                    'https://$API_HOST/api/hitomi/images/preview/$hash.webp',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          // 상태 오버레이
          if (isAnalyzing || isAnalyzed || error != null)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.black54,
              ),
              child: Center(
                child: isAnalyzing
                    ? const CircularProgressIndicator()
                    : error != null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 40),
                              const SizedBox(height: 8),
                              const Icon(Icons.refresh, color: Colors.white, size: 24),
                              const SizedBox(height: 4),
                              Text(
                                '탭하여 재시도',
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ],
                          )
                        : const Icon(Icons.check_circle,
                            color: Colors.green, size: 40),
              ),
            ),
          // 인덱스 배지
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeImage(String imageUrl, int index) async {
    if (!embeddingService.isModelReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모델이 다운로드되지 않았습니다. 설정에서 다운로드하세요.')),
      );
      return;
    }

    if (analyzing[index] == true) {
      return; // 이미 분석 중
    }

    setState(() {
      analyzing[index] = true;
      analysisErrors[index] = null;
    });

    try {
      debugPrint('🔄 이미지 $index 분석 시작: $imageUrl');
      
      // 이미지 다운로드
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        debugPrint('  - 응답 본문 전체:\n${response.body}');
        throw Exception('이미지 다운로드 실패 (Status ${response.statusCode})');
      }

      debugPrint('  - 다운로드 성공: ${response.bodyBytes.length} bytes');

      // 임베딩 생성
      final embedding = await embeddingService.getImageEmbedding(
        response.bodyBytes,
      );

      debugPrint('✅ 이미지 $index 분석 완료 (임베딩 차원: ${embedding.length})');

      setState(() {
        analyzed[index] = true;
        analyzing[index] = false;
      });

      // 임베딩 저장 (나중에 추가 가능)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 ${index + 1} 분석 완료')),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ 이미지 $index 분석 실패:');
      debugPrint('  - URL: $imageUrl');
      debugPrint('  - 에러: $e');
      debugPrint('  - 스택 트레이스: $stackTrace');
      
      setState(() {
        analysisErrors[index] = e.toString();
        analyzing[index] = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('분석 실패 (이미지 ${index + 1}): $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _retryImage(String imageUrl, int index) async {
    debugPrint('🔄 이미지 $index 재시도');
    
    // 에러 상태 초기화
    setState(() {
      analysisErrors[index] = null;
    });

    // 재분석
    await _analyzeImage(imageUrl, index);
  }

  Future<void> _retryFailedImages() async {
    if (!embeddingService.isModelReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모델이 다운로드되지 않았습니다. 설정에서 다운로드하세요.')),
      );
      return;
    }

    final snapshot = await detail;
    final files = snapshot['files'] as List;

    // 실패한 이미지 인덱스 찾기
    final failedIndices = <int>[];
    for (var i = 0; i < files.length; i++) {
      if (analysisErrors[i] != null) {
        failedIndices.add(i);
      }
    }

    if (failedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('실패한 항목이 없습니다')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('실패한 항목 재시도'),
        content: Text(
          '실패한 ${failedIndices.length}장의 이미지를 다시 분석합니다.\n\n'
          '계속하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('재시도'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    int successCount = 0;
    for (final i in failedIndices) {
      final hash = files[i]['hash'];
      final imageUrl = useThumbnail
          ? 'https://$API_HOST/api/hitomi/images/preview/$hash.webp'
          : 'https://$API_HOST/api/hitomi/images/$hash.webp';

      // 에러 상태 초기화
      setState(() {
        analysisErrors[i] = null;
      });

      await _analyzeImage(imageUrl, i);

      // 성공했는지 확인
      if (analysisErrors[i] == null && analyzed[i] == true) {
        successCount++;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '재시도 완료\n'
          '성공: $successCount개\n'
          '실패: ${failedIndices.length - successCount}개',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _analyzeAll() async {
    if (!embeddingService.isModelReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모델이 다운로드되지 않았습니다. 설정에서 다운로드하세요.')),
      );
      return;
    }

    final snapshot = await detail;
    final files = snapshot['files'] as List;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('전체 분석'),
        content: Text(
          '총 ${files.length}장의 이미지를 분석합니다.\n'
          '이미지: ${useThumbnail ? "썸네일" : "원본"}\n'
          '예상 시간: ${files.length * 2}초\n\n'
          '계속하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('시작'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    for (var i = 0; i < files.length; i++) {
      if (analyzed[i] == true) {
        continue; // 이미 분석된 이미지는 건너뛰기
      }

      final hash = files[i]['hash'];
      final imageUrl = useThumbnail
          ? 'https://$API_HOST/api/hitomi/images/preview/$hash.webp'
          : 'https://$API_HOST/api/hitomi/images/$hash.webp';

      await _analyzeImage(imageUrl, i);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('전체 분석 완료')),
    );
  }
}
