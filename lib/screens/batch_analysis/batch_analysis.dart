import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hitomiviewer/constants/api.dart';
import 'package:hitomiviewer/services/gemma.dart';
import 'package:hitomiviewer/services/hitomi.dart';
import 'package:hitomiviewer/store.dart';
import 'package:provider/provider.dart';

enum BatchAnalysisState { idle, running, paused, completed, error }

@RoutePage()
class BatchAnalysisScreen extends StatefulWidget {
  const BatchAnalysisScreen({Key? key}) : super(key: key);

  @override
  State<BatchAnalysisScreen> createState() => _BatchAnalysisScreenState();
}

class _BatchAnalysisScreenState extends State<BatchAnalysisScreen> {
  final gemmaService = GemmaService();
  BatchAnalysisState _state = BatchAnalysisState.idle;
  ImageQuality _selectedQuality = ImageQuality.thumbnail;
  
  int _currentIndex = 0;
  int _totalCount = 0;
  List<int> _galleryIds = [];
  List<int> _failedGalleries = [];
  Map<int, String> _galleryTitles = {};
  Map<int, String> _analysisStatus = {};
  
  bool _isPaused = false;
  DateTime? _startTime;
  
  @override
  void initState() {
    super.initState();
    _selectedQuality = context.read<Store>().imageQuality;
    gemmaService.checkModelStatus();
    _loadGalleries();
  }

  void _loadGalleries() {
    final store = context.read<Store>();
    _galleryIds = List.from(store.favorite);
    _totalCount = _galleryIds.length;
    
    // 이미 분석된 갤러리 상태 표시
    for (var id in _galleryIds) {
      if (store.galleryEmbeddings.containsKey(id)) {
        _analysisStatus[id] = '분석 완료';
      } else {
        _analysisStatus[id] = '대기 중';
      }
    }
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('배치 분석'),
      ),
      body: Column(
        children: [
          // 상단 진행 상태 카드
          _buildProgressCard(),
          // 갤러리 목록
          Expanded(
            child: _buildGalleryList(),
          ),
          // 하단 컨트롤 버튼
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final store = context.watch<Store>();
    final analyzedCount = store.analyzedFavoriteCount;
    final progress = _totalCount > 0 ? analyzedCount / _totalCount : 0.0;
    
    // 예상 완료 시간 계산
    String estimatedTime = '';
    if (_state == BatchAnalysisState.running && _startTime != null) {
      final elapsed = DateTime.now().difference(_startTime!).inSeconds;
      if (_currentIndex > 0) {
        final avgTimePerGallery = elapsed / _currentIndex;
        final remaining = (_totalCount - _currentIndex) * avgTimePerGallery;
        final minutes = (remaining / 60).floor();
        final seconds = (remaining % 60).floor();
        estimatedTime = '예상 완료: ${minutes}분 ${seconds}초';
      }
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '전체 진행률',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '$analyzedCount / $_totalCount',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.high_quality, size: 16),
                  label: Text(
                    _selectedQuality == ImageQuality.thumbnail
                        ? '썸네일 (빠름)'
                        : '원본 (고품질)',
                  ),
                ),
                const SizedBox(width: 8),
                if (_state == BatchAnalysisState.running)
                  Chip(
                    avatar: const Icon(Icons.timer, size: 16),
                    label: Text(estimatedTime),
                  ),
                if (_failedGalleries.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.error, size: 16),
                    label: Text('실패: ${_failedGalleries.length}개'),
                    backgroundColor: Colors.red.shade100,
                  ),
              ],
            ),
            if (_state == BatchAnalysisState.idle) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _showQualityDialog,
                icon: const Icon(Icons.settings),
                label: const Text('품질 변경'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryList() {
    if (_galleryIds.isEmpty) {
      return const Center(
        child: Text('좋아요한 갤러리가 없습니다'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _galleryIds.length,
      itemBuilder: (context, index) {
        final galleryId = _galleryIds[index];
        final status = _analysisStatus[galleryId] ?? '대기 중';
        final isCurrent = index == _currentIndex && _state == BatchAnalysisState.running;
        final isFailed = _failedGalleries.contains(galleryId);

        return FutureBuilder<Map<String, dynamic>>(
          future: fetchDetail(galleryId.toString()),
          builder: (context, snapshot) {
            String title = '갤러리 #$galleryId';
            if (snapshot.hasData) {
              title = snapshot.data!['title'] ?? title;
              _galleryTitles[galleryId] = title;
            } else if (_galleryTitles.containsKey(galleryId)) {
              title = _galleryTitles[galleryId]!;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: isCurrent
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isFailed
                      ? Colors.red
                      : status == '분석 완료'
                          ? Colors.green
                          : isCurrent
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                  child: isFailed
                      ? const Icon(Icons.error, color: Colors.white)
                      : status == '분석 완료'
                          ? const Icon(Icons.check, color: Colors.white)
                          : isCurrent
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                ),
                title: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(status),
                trailing: status == '분석 완료'
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : isFailed
                        ? const Icon(Icons.error, color: Colors.red)
                        : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildControlButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_state == BatchAnalysisState.idle) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: gemmaService.isModelReady ? _startAnalysis : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('분석 시작'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ] else if (_state == BatchAnalysisState.running) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pauseAnalysis,
                  icon: const Icon(Icons.pause),
                  label: const Text('일시정지'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _stopAnalysis,
                icon: const Icon(Icons.stop),
                label: const Text('중지'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else if (_state == BatchAnalysisState.paused) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _resumeAnalysis,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('재개'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _stopAnalysis,
                icon: const Icon(Icons.stop),
                label: const Text('중지'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else if (_state == BatchAnalysisState.completed) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check),
                  label: const Text('완료'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
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
            const Text(
              '배치 분석에 사용할 이미지 품질을 선택하세요.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            RadioListTile<ImageQuality>(
              title: const Text('썸네일 (권장)'),
              subtitle: const Text('~300KB, 빠른 처리 (3-5초/이미지)'),
              value: ImageQuality.thumbnail,
              groupValue: _selectedQuality,
              onChanged: (value) {
                setState(() {
                  _selectedQuality = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<ImageQuality>(
              title: const Text('원본 (고품질)'),
              subtitle: const Text(
                '수MB, 상세 분석 (10-30초/이미지)\n데이터 사용량 증가',
              ),
              value: ImageQuality.original,
              groupValue: _selectedQuality,
              onChanged: (value) {
                setState(() {
                  _selectedQuality = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startAnalysis() async {
    if (!gemmaService.isModelReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모델이 설치되지 않았습니다. 설정에서 다운로드하세요.'),
        ),
      );
      return;
    }

    if (_galleryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('분석할 갤러리가 없습니다')),
      );
      return;
    }

    // 확인 대화상자
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('배치 분석 시작'),
        content: Text(
          '총 $_totalCount개의 갤러리를 분석합니다.\n'
          '품질: ${_selectedQuality == ImageQuality.thumbnail ? "썸네일" : "원본"}\n'
          '예상 시간: ${_selectedQuality == ImageQuality.thumbnail ? _totalCount * 5 : _totalCount * 20}초\n\n'
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

    if (confirm != true || !mounted) return;

    setState(() {
      _state = BatchAnalysisState.running;
      _currentIndex = 0;
      _failedGalleries.clear();
      _isPaused = false;
      _startTime = DateTime.now();
    });

    await _processGalleries();
  }

  Future<void> _processGalleries() async {
    for (; _currentIndex < _galleryIds.length; _currentIndex++) {
      if (_isPaused || _state != BatchAnalysisState.running) {
        break;
      }

      final galleryId = _galleryIds[_currentIndex];
      final store = context.read<Store>();

      // 이미 분석된 갤러리는 건너뛰기
      if (store.galleryEmbeddings.containsKey(galleryId)) {
        setState(() {
          _analysisStatus[galleryId] = '분석 완료 (캐시)';
        });
        continue;
      }

      setState(() {
        _analysisStatus[galleryId] = '분석 중...';
      });

      try {
        // 갤러리 정보 가져오기
        final detail = await fetchDetail(galleryId.toString());
        final files = detail['files'] as List;

        if (files.isEmpty) {
          throw Exception('이미지가 없습니다');
        }

        // 첫 번째 이미지만 분석 (대표 이미지)
        final hash = files[0]['hash'];
        final imageUrl = _selectedQuality == ImageQuality.thumbnail
            ? 'https://$API_HOST/api/hitomi/images/preview/$hash.webp'
            : 'https://$API_HOST/api/hitomi/images/$hash.webp';

        // 이미지 분석
        final result = await gemmaService.analyzeImage(
          imageUrl,
          quality: _selectedQuality,
        );

        // 분석 결과 저장
        await store.saveImageAnalysis(galleryId, result, _selectedQuality);

        // 임베딩 생성 및 저장
        final embedding = await gemmaService.getTextEmbedding(result);
        await store.saveGalleryEmbedding(galleryId, embedding);

        setState(() {
          _analysisStatus[galleryId] = '분석 완료';
        });
      } catch (e) {
        _failedGalleries.add(galleryId);
        setState(() {
          _analysisStatus[galleryId] = '실패: $e';
        });
      }
    }

    if (!_isPaused && _state == BatchAnalysisState.running) {
      setState(() {
        _state = BatchAnalysisState.completed;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '배치 분석 완료\n'
              '성공: ${_currentIndex - _failedGalleries.length}개\n'
              '실패: ${_failedGalleries.length}개',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _pauseAnalysis() {
    setState(() {
      _state = BatchAnalysisState.paused;
      _isPaused = true;
    });
  }

  void _resumeAnalysis() {
    setState(() {
      _state = BatchAnalysisState.running;
      _isPaused = false;
    });
    _processGalleries();
  }

  void _stopAnalysis() {
    setState(() {
      _state = BatchAnalysisState.idle;
      _isPaused = false;
      _currentIndex = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('분석이 중지되었습니다')),
    );
  }
}

