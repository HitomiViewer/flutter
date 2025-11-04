import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
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

  // 이미지별 분석 상태
  Map<int, bool> analyzing = {};
  Map<int, bool> analyzed = {};
  Map<int, String?> analysisErrors = {};
  Map<int, int> imageRefreshKeys = {}; // 이미지 새로고침을 위한 키
  Map<int, String?> imageLoadErrors = {}; // 이미지 로딩 에러
  Map<int, List<double>?> imageEmbeddings = {}; // 이미지별 임베딩 저장

  @override
  void initState() {
    super.initState();
    detail = fetchDetail(widget.id.toString());
    // PE-Core 모델은 앱 시작 시 초기화됨
  }

  String _parseImageError(Object error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('invalid image data')) {
      return '손상된 이미지';
    } else if (errorStr.contains('404')) {
      return '이미지 없음 (404)';
    } else if (errorStr.contains('403')) {
      return '접근 거부 (403)';
    } else if (errorStr.contains('timeout')) {
      return '타임아웃';
    } else if (errorStr.contains('network')) {
      return '네트워크 에러';
    } else if (errorStr.contains('failed host lookup')) {
      return 'DNS 에러';
    } else if (errorStr.contains('connection refused')) {
      return '연결 거부';
    } else if (errorStr.contains('socket')) {
      return '소켓 에러';
    } else if (errorStr.contains('http')) {
      // HTTP 상태 코드 추출
      final match = RegExp(r'(\d{3})').firstMatch(errorStr);
      if (match != null) {
        return 'HTTP ${match.group(1)}';
      }
      return 'HTTP 에러';
    } else {
      // 에러 메시지 간략화
      final shortError = error.toString().split(':').first;
      return shortError.length > 20 
          ? '${shortError.substring(0, 20)}...' 
          : shortError;
    }
  }

  void _showErrorDetails(int index, String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text('이미지 ${index + 1} 에러'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '에러 유형:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              errorMessage,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '해결 방법:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(_getErrorSolution(errorMessage)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              final hash = detail.then((d) => d['files'][index]['hash']);
              hash.then((h) {
                final imageUrl = 'https://$API_HOST/api/hitomi/images/$h.webp';
                _clearCacheAndRetry(imageUrl, imageUrl, index);
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('재시도'),
          ),
        ],
      ),
    );
  }

  String _getErrorSolution(String errorMessage) {
    if (errorMessage.contains('손상된')) {
      return '캐시를 제거하고 재시도하세요.\n이 문제가 계속되면 서버의 이미지가 손상되었을 수 있습니다.';
    } else if (errorMessage.contains('404')) {
      return '이미지가 서버에 존재하지 않습니다.\n다른 이미지를 시도해보세요.';
    } else if (errorMessage.contains('403')) {
      return '서버가 접근을 거부했습니다.\nVPN을 사용하거나 잠시 후 다시 시도하세요.';
    } else if (errorMessage.contains('타임아웃')) {
      return '네트워크가 느리거나 서버가 응답하지 않습니다.\n인터넷 연결을 확인하고 재시도하세요.';
    } else if (errorMessage.contains('네트워크') || errorMessage.contains('DNS')) {
      return '인터넷 연결을 확인하세요.\nWi-Fi 또는 데이터 연결이 정상인지 확인하세요.';
    } else {
      return '알 수 없는 에러입니다.\n캐시를 제거하고 재시도해보세요.';
    }
  }

  void _showAnalysisInfo(int index) {
    final embedding = imageEmbeddings[index];
    if (embedding == null) {
      return;
    }

    // 임베딩 통계 계산
    final mean = embedding.reduce((a, b) => a + b) / embedding.length;
    final variance = embedding.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / embedding.length;
    final stdDev = sqrt(variance);
    final minVal = embedding.reduce((a, b) => a < b ? a : b);
    final maxVal = embedding.reduce((a, b) => a > b ? a : b);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.analytics, color: Colors.blue),
            const SizedBox(width: 8),
            Text('이미지 ${index + 1} 분석 정보'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('임베딩 차원', '${embedding.length}차원'),
              const Divider(),
              _buildInfoRow('평균값', mean.toStringAsFixed(6)),
              _buildInfoRow('표준편차', stdDev.toStringAsFixed(6)),
              _buildInfoRow('최소값', minVal.toStringAsFixed(6)),
              _buildInfoRow('최대값', maxVal.toStringAsFixed(6)),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                '벡터 미리보기',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '[${embedding.take(10).map((e) => e.toStringAsFixed(3)).join(', ')}, ...]',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '이 임베딩은 이미지의 시각적 특징을 수치화한 것입니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // 유사한 이미지 찾기 기능을 나중에 추가 가능
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('유사 이미지 검색 기능은 추후 추가 예정입니다'),
                ),
              );
            },
            icon: const Icon(Icons.search),
            label: const Text('유사 이미지 찾기'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('갤러리 분석'),
        actions: [
          // 전체 캐시 제거 버튼
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: '전체 캐시 제거',
            onPressed: _clearAllCache,
          ),
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
                  label: const Text('원본 이미지'),
                  avatar: const Icon(Icons.high_quality, size: 16),
                  backgroundColor: Colors.blue.shade100,
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
    // preview가 손상된 경우가 있으므로 원본 사용
    final imageUrl = 'https://$API_HOST/api/hitomi/images/$hash.webp';

    final isAnalyzing = analyzing[index] ?? false;
    final isAnalyzed = analyzed[index] ?? false;
    final error = analysisErrors[index];

    return GestureDetector(
      onTap: () {
        if (isAnalyzed) {
          // 분석 완료 → 분석 정보 표시
          _showAnalysisInfo(index);
        } else if (error != null) {
          // 에러 → 재시도
          _retryImage(imageUrl, index);
        } else if (!isAnalyzing) {
          // 대기 중 → 분석 시작
          _analyzeImage(imageUrl, index);
        }
      },
      onLongPress: () {
        // 길게 누르면 캐시 제거 및 재시도
        _clearCacheAndRetry(imageUrl, imageUrl, index);
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
                key: ValueKey('image_${index}_${imageRefreshKeys[index] ?? 0}'),
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) {
                  // 에러 정보 저장
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        imageLoadErrors[index] = _parseImageError(error);
                      });
                    }
                  });
                  
                  return GestureDetector(
                    onTap: () {
                      _clearCacheAndRetry(imageUrl, imageUrl, index);
                    },
                    child: Container(
                      color: Colors.grey[800],
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.broken_image,
                              color: Colors.red,
                              size: 36,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _parseImageError(error),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.red[300],
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            const Icon(
                              Icons.refresh,
                              color: Colors.white70,
                              size: 18,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '탭하여 재시도',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // 상태 오버레이
          if (isAnalyzing || isAnalyzed || error != null)
            GestureDetector(
              onTap: () {
                if (isAnalyzed) {
                  _showAnalysisInfo(index);
                } else if (error != null) {
                  _clearCacheAndRetry(imageUrl, imageUrl, index);
                }
              },
              child: Container(
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
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 40),
                                const SizedBox(height: 8),
                                const Icon(Icons.info_outline,
                                    color: Colors.white, size: 24),
                                const SizedBox(height: 4),
                                Text(
                                  '탭하여 정보 보기',
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ],
                            ),
                ),
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
          // 에러 정보 배지 (하단)
          if (imageLoadErrors[index] != null)
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  _showErrorDetails(index, imageLoadErrors[index]!);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          imageLoadErrors[index]!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
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
        debugPrint('  - HTTP 에러: ${response.statusCode}');
        debugPrint('  - 응답 본문 일부:\n${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}');
        throw Exception('이미지 다운로드 실패 (HTTP ${response.statusCode})');
      }

      final imageBytes = response.bodyBytes;
      debugPrint('  - 다운로드 성공: ${imageBytes.length} bytes');

      // 이미지 데이터 유효성 검증
      if (imageBytes.isEmpty) {
        debugPrint('  ❌ 빈 이미지 데이터');
        throw Exception('빈 이미지 데이터');
      }
      
      if (imageBytes.length < 100) {
        debugPrint('  ❌ 이미지 데이터가 너무 작음: ${imageBytes.length} bytes');
        throw Exception('이미지 데이터가 너무 작음 (${imageBytes.length} bytes)');
      }

      // WebP/이미지 파일 헤더 검증 (선택적)
      final header = imageBytes.take(16).toList();
      debugPrint('  - 파일 헤더: ${header.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

      // 임베딩 생성
      final embedding = await embeddingService.getImageEmbedding(imageBytes);

      debugPrint('✅ 이미지 $index 분석 완료 (임베딩 차원: ${embedding.length})');

      setState(() {
        analyzed[index] = true;
        analyzing[index] = false;
        imageEmbeddings[index] = embedding; // 임베딩 저장
      });

      // 임베딩 저장 (나중에 추가 가능)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 ${index + 1} 분석 완료 (탭하여 정보 보기)'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 이미지 $index 분석 실패:');
      debugPrint('  - URL: $imageUrl');
      debugPrint('  - 에러: $e');
      
      // 스택 트레이스는 필요한 경우에만 출력
      if (e.toString().contains('타임아웃') || 
          e.toString().contains('디코딩') ||
          e.toString().contains('전처리')) {
        debugPrint('  - 스택 트레이스 (첫 5줄):');
        final lines = stackTrace.toString().split('\n');
        for (var i = 0; i < (lines.length < 5 ? lines.length : 5); i++) {
          debugPrint('    ${lines[i]}');
        }
      }
      
      setState(() {
        analysisErrors[index] = e.toString();
        analyzing[index] = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('분석 실패 (이미지 ${index + 1}): ${e.toString().split(':').first}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
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

  Future<void> _clearAllCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('전체 캐시 제거'),
        content: const Text(
          '모든 이미지 캐시를 제거하고 새로 다운로드합니다.\n\n'
          '계속하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('제거'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      debugPrint('🧹 전체 캐시 제거 시작');
      
      final cacheManager = DefaultCacheManager();
      
      // 갤러리의 모든 이미지 캐시 제거
      final snapshot = await detail;
      final files = snapshot['files'] as List;
      
      int removedCount = 0;
      for (var i = 0; i < files.length; i++) {
        final hash = files[i]['hash'];
        final imageUrl = 'https://$API_HOST/api/hitomi/images/$hash.webp';
        
        debugPrint('  - 이미지 ${i + 1} 캐시 제거 중...');
        await cacheManager.removeFile(imageUrl);
        
        // Flutter 이미지 캐시도 제거
        try {
          final imageProvider = CachedNetworkImageProvider(imageUrl);
          await imageProvider.evict();
        } catch (e) {
          // 무시
        }
        
        removedCount++;
      }
      
      debugPrint('✅ $removedCount개 캐시 제거 완료');
      
      // 모든 이미지 새로고침
      setState(() {
        for (var i = 0; i < files.length; i++) {
          imageRefreshKeys[i] = (imageRefreshKeys[i] ?? 0) + 1;
          analysisErrors[i] = null;
          imageLoadErrors[i] = null; // 이미지 로딩 에러 초기화
          analyzed[i] = false;
          imageEmbeddings[i] = null; // 임베딩 데이터 초기화
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('전체 캐시 제거 완료\n${files.length}개 이미지 다시 로딩 중...'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      debugPrint('✅ 전체 새로고침 완료');
    } catch (e, stackTrace) {
      debugPrint('❌ 전체 캐시 제거 실패: $e');
      debugPrint('  스택 트레이스: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('전체 캐시 제거 실패: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearCacheAndRetry(String imageUrl, String _, int index) async {
    debugPrint('🧹 이미지 ${index + 1} 캐시 제거 및 재시도');
    debugPrint('  - 이미지 URL: $imageUrl');
    
    try {
      final cacheManager = DefaultCacheManager();
      
      // 캐시 확인
      final cachedFile = await cacheManager.getFileFromCache(imageUrl);
      if (cachedFile != null) {
        final fileSize = await cachedFile.file.length();
        debugPrint('  - 기존 캐시 발견: ${cachedFile.file.path}');
        debugPrint('  - 캐시 크기: $fileSize bytes');
        
        // 1000 bytes 이하는 손상된 것으로 간주
        if (fileSize < 1000) {
          debugPrint('  ⚠️  캐시가 너무 작음 ($fileSize bytes) → 손상된 이미지로 추정');
        }
      } else {
        debugPrint('  - 캐시 없음');
      }
      
      // Flutter의 이미지 캐시에서도 제거 (중요!)
      try {
        final imageProvider = CachedNetworkImageProvider(imageUrl);
        await imageProvider.evict();
        debugPrint('  ✅ Flutter 이미지 캐시 제거 완료');
      } catch (e) {
        debugPrint('  ⚠️  Flutter 이미지 캐시 제거 실패: $e');
      }
      
      // 파일 캐시 제거
      await cacheManager.removeFile(imageUrl);
      debugPrint('  ✅ 이미지 캐시 제거 완료');
      
      // 이미지 새로고침 키 증가 (위젯 강제 재빌드)
      final newKey = (imageRefreshKeys[index] ?? 0) + 1;
      setState(() {
        imageRefreshKeys[index] = newKey;
        analysisErrors[index] = null;
        imageLoadErrors[index] = null;
        analyzed[index] = false;
        imageEmbeddings[index] = null; // 임베딩 데이터 초기화
      });
      
      debugPrint('  ✅ 새로고침 키: $newKey → 위젯 재빌드 트리거');
      
      // 약간의 딜레이를 주어 setState가 완전히 적용되도록
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 ${index + 1} 다시 로딩 중...'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );
      }
      
      debugPrint('✅ 캐시 제거 완료 → 이미지 다운로드가 자동으로 시작됩니다');
      
      // CachedNetworkImage가 자동으로 다운로드를 시작함
      // 추가로 5초 후 상태 확인
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && imageLoadErrors[index] != null) {
          debugPrint('  ⚠️  5초 후에도 에러 발생 → 서버 문제일 수 있음');
        }
      });
      
    } catch (e, stackTrace) {
      debugPrint('❌ 캐시 제거 실패: $e');
      debugPrint('  스택 트레이스: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('캐시 제거 실패: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      final imageUrl = 'https://$API_HOST/api/hitomi/images/$hash.webp';

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
          '이미지: 원본 (고품질)\n'
          '예상 시간: ${files.length * 3}초\n\n'
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
      final imageUrl = 'https://$API_HOST/api/hitomi/images/$hash.webp';

      await _analyzeImage(imageUrl, i);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('전체 분석 완료')),
    );
  }
}
