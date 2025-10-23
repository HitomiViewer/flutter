import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hitomiviewer/constants/api.dart';
import 'package:hitomiviewer/services/gemma.dart';
import 'package:hitomiviewer/services/hitomi.dart';
import 'package:hitomiviewer/store.dart';
import 'package:provider/provider.dart';

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
  final gemmaService = GemmaService();
  ImageQuality selectedQuality = ImageQuality.thumbnail;
  
  // 이미지별 분석 상태
  Map<int, bool> analyzing = {};
  Map<int, String?> analysisResults = {};
  Map<int, String?> analysisErrors = {};

  @override
  void initState() {
    super.initState();
    detail = fetchDetail(widget.id.toString());
    selectedQuality = context.read<Store>().imageQuality;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('갤러리 분석'),
        actions: [
          // 품질 선택 버튼
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showQualityDialog,
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
                _buildInfoCard(snapshot.data!),
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

  Widget _buildInfoCard(Map<String, dynamic> data) {
    final files = data['files'] as List;
    final analyzedCount = analysisResults.values.where((r) => r != null).length;
    
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
                  label: Text('총 ${files.length}장'),
                  avatar: const Icon(Icons.image, size: 16),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text('분석 완료 $analyzedCount장'),
                  avatar: const Icon(Icons.check_circle, size: 16),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(selectedQuality == ImageQuality.thumbnail
                      ? '썸네일'
                      : '원본'),
                  avatar: const Icon(Icons.high_quality, size: 16),
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
    final imageUrl = selectedQuality == ImageQuality.thumbnail
        ? 'https://$API_HOST/api/hitomi/images/preview/$hash.webp'
        : 'https://$API_HOST/api/hitomi/images/$hash.webp';

    final isAnalyzing = analyzing[index] ?? false;
    final result = analysisResults[index];
    final error = analysisErrors[index];

    return GestureDetector(
      onTap: () => _analyzeImage(imageUrl, index),
      onLongPress: result != null ? () => _showAnalysisResult(result, index) : null,
      child: Stack(
        children: [
          // 이미지
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: result != null ? Colors.green : Colors.grey,
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
          if (isAnalyzing || result != null || error != null)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.black54,
              ),
              child: Center(
                child: isAnalyzing
                    ? const CircularProgressIndicator()
                    : error != null
                        ? const Icon(Icons.error, color: Colors.red, size: 40)
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

  void _showQualityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('분석 품질 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ImageQuality>(
              title: const Text('썸네일 (권장)'),
              subtitle: const Text('~300KB, 빠른 처리 (3-5초/이미지)'),
              value: ImageQuality.thumbnail,
              groupValue: selectedQuality,
              onChanged: (value) {
                setState(() {
                  selectedQuality = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<ImageQuality>(
              title: const Text('원본 (고품질)'),
              subtitle: const Text('수MB, 상세 분석 (10-30초/이미지)\n데이터 사용량 증가'),
              value: ImageQuality.original,
              groupValue: selectedQuality,
              onChanged: (value) {
                setState(() {
                  selectedQuality = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeImage(String imageUrl, int index) async {
    if (!gemmaService.isModelReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모델이 설치되지 않았습니다. 설정에서 다운로드하세요.')),
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
      final result = await gemmaService.analyzeImage(
        imageUrl,
        quality: selectedQuality,
      );

      setState(() {
        analysisResults[index] = result;
        analyzing[index] = false;
      });

      // 분석 결과 저장
      final store = context.read<Store>();
      await store.saveImageAnalysis(widget.id, result, selectedQuality);

      // 임베딩 생성 및 저장
      final embedding = await gemmaService.getTextEmbedding(result);
      await store.saveGalleryEmbedding(widget.id, embedding);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 ${index + 1} 분석 완료')),
      );
    } catch (e) {
      setState(() {
        analysisErrors[index] = e.toString();
        analyzing[index] = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('분석 실패: $e')),
      );
    }
  }

  void _showAnalysisResult(String result, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '이미지 ${index + 1} 분석 결과',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Text(result),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _analyzeAll() async {
    if (!gemmaService.isModelReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모델이 설치되지 않았습니다. 설정에서 다운로드하세요.')),
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
          '품질: ${selectedQuality == ImageQuality.thumbnail ? "썸네일" : "원본"}\n'
          '예상 시간: ${selectedQuality == ImageQuality.thumbnail ? files.length * 5 : files.length * 20}초\n\n'
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
      if (analysisResults[i] != null) {
        continue; // 이미 분석된 이미지는 건너뛰기
      }

      final hash = files[i]['hash'];
      final imageUrl = selectedQuality == ImageQuality.thumbnail
          ? 'https://$API_HOST/api/hitomi/images/preview/$hash.webp'
          : 'https://$API_HOST/api/hitomi/images/$hash.webp';

      await _analyzeImage(imageUrl, i);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('전체 분석 완료')),
    );
  }
}

