import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';
import 'package:http/http.dart' as http;

enum EmbeddingModel {
  peCore, // PE-Core-L14-336
}

enum ModelStatus {
  notLoaded,
  loading,
  loaded,
  error,
}

// Isolate 통신 프로토콜
enum IsolateRequestType {
  initialize,
  processImage,
  processText,
  dispose,
}

class IsolateRequest {
  final String id;
  final IsolateRequestType type;
  final Map<String, dynamic> data;

  IsolateRequest({
    required this.id,
    required this.type,
    required this.data,
  });
}

class IsolateResponse {
  final String id;
  final bool success;
  final dynamic result;
  final String? error;

  IsolateResponse({
    required this.id,
    required this.success,
    this.result,
    this.error,
  });
}

class SimilarImageResult {
  final int id;
  final double similarity;

  SimilarImageResult({
    required this.id,
    required this.similarity,
  });
}

class ImageEmbeddingService extends ChangeNotifier {
  static final ImageEmbeddingService _instance =
      ImageEmbeddingService._internal();
  factory ImageEmbeddingService() => _instance;
  ImageEmbeddingService._internal();

  // Isolate 관리
  Isolate? _workerIsolate;
  SendPort? _workerSendPort;
  ReceivePort? _mainReceivePort;
  
  // 요청-응답 매칭
  final Map<String, Completer<IsolateResponse>> _pendingRequests = {};
  int _requestCounter = 0;

  ModelStatus _status = ModelStatus.notLoaded;
  String? _errorMessage;

  ModelStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isModelReady => _status == ModelStatus.loaded;

  // 모델 설정
  static const int imageSize = 336; // PE-Core-L14는 336x336
  static const int embeddingDim = 1024; // PE-Core-L14는 1024차원
  static const int maxTokens = 32; // CLIP 텍스트 최대 토큰 수

  /// 앱 시작 시 Worker Isolate 생성 및 모델 로드
  Future<void> initialize() async {
    try {
      _status = ModelStatus.loading;
      _errorMessage = null;
      notifyListeners();

      debugPrint('🚀 Worker Isolate 생성 중...');

      // ReceivePort 생성 (메인 스레드에서 메시지 수신)
      _mainReceivePort = ReceivePort();

      // 메인 스레드에서 모델 데이터 로드
      debugPrint('📦 메인 스레드에서 모델 데이터 로드 중...');
      
      final visionModelData = await rootBundle.load(
        'assets/models/pe_core_vision_l14.onnx',
      );
      
      final textModelData = await rootBundle.load(
        'assets/models/pe_core_text_l14.onnx',
      );
      
      debugPrint('✅ 모델 데이터 로드 완료');

      // Worker Isolate 생성 (모델 데이터와 SendPort 함께 전달)
      _workerIsolate = await Isolate.spawn(
        _isolateEntryPoint,
        {
          'sendPort': _mainReceivePort!.sendPort,
          'visionModelData': visionModelData.buffer.asUint8List(),
          'textModelData': textModelData.buffer.asUint8List(),
        },
        debugName: 'ImageEmbeddingWorker',
      );

      // Worker로부터 메시지 수신 대기
      final completer = Completer<SendPort>();
      bool sendPortReceived = false;
      
      _mainReceivePort!.listen((message) {
        if (message is SendPort && !sendPortReceived) {
          // 첫 메시지: Worker의 SendPort
          sendPortReceived = true;
          _workerSendPort = message;
          completer.complete(message);
        } else if (message is IsolateResponse) {
          // 일반 응답 처리
          final responseCompleter = _pendingRequests.remove(message.id);
          responseCompleter?.complete(message);
        }
      });

      // Worker SendPort 수신 대기 (타임아웃 10초)
      _workerSendPort = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Worker Isolate 초기화 타임아웃'),
      );

      debugPrint('✅ Worker Isolate 생성 완료');

      // Worker에게 모델 초기화 요청
      debugPrint('📦 PE-Core ONNX 모델 로드 중...');
      final response = await _sendRequest(
        IsolateRequestType.initialize,
        {},
      );

      if (!response.success) {
        throw Exception(response.error ?? '모델 초기화 실패');
      }

      _status = ModelStatus.loaded;
      debugPrint('✅ PE-Core 모델 초기화 완료 (Isolate)');
      notifyListeners();
    } catch (e) {
      _status = ModelStatus.error;
      _errorMessage = e.toString();
      debugPrint('❌ 모델 초기화 실패: $e');
      
      // 실패 시 정리
      _workerIsolate?.kill(priority: Isolate.immediate);
      _workerIsolate = null;
      _mainReceivePort?.close();
      _mainReceivePort = null;
      _workerSendPort = null;
      
      notifyListeners();
      rethrow;
    }
  }

  /// Worker Isolate에 요청 전송 및 응답 대기
  Future<IsolateResponse> _sendRequest(
    IsolateRequestType type,
    Map<String, dynamic> data,
  ) async {
    if (_workerSendPort == null) {
      throw Exception('Worker Isolate가 초기화되지 않았습니다');
    }

    final requestId = 'req_${_requestCounter++}';
    final completer = Completer<IsolateResponse>();
    _pendingRequests[requestId] = completer;

    final request = IsolateRequest(
      id: requestId,
      type: type,
      data: data,
    );

    _workerSendPort!.send(request);

    // 응답 대기 (타임아웃 60초)
    try {
      return await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          _pendingRequests.remove(requestId);
          throw TimeoutException('Worker Isolate 응답 타임아웃');
        },
      );
    } catch (e) {
      _pendingRequests.remove(requestId);
      rethrow;
    }
  }


  /// 이미지 전처리 (PE-Core: 336x336, ImageNet 정규화)
  /// 백그라운드에서 실행 가능한 독립 함수
  static Float32List _preprocessImage(Uint8List imageBytes) {
    // 이미지 디코딩
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      debugPrint('❌ 이미지 디코딩 실패: ${imageBytes.length} bytes');
      throw Exception('이미지 디코딩 실패 (크기: ${imageBytes.length} bytes)');
    }
    
    debugPrint('✅ 이미지 디코딩 성공: ${image.width}x${image.height}');

    // 336x336로 리사이즈 (center crop)
    final resized = img.copyResize(image, width: imageSize, height: imageSize);

    // ImageNet 정규화
    // mean = [0.485, 0.456, 0.406]
    // std = [0.229, 0.224, 0.225]
    const mean = [0.485, 0.456, 0.406];
    const std = [0.229, 0.224, 0.225];

    // NCHW 포맷으로 변환 [1, 3, 336, 336]
    final input = Float32List(1 * 3 * imageSize * imageSize);

    for (var y = 0; y < imageSize; y++) {
      for (var x = 0; x < imageSize; x++) {
        final pixel = resized.getPixel(x, y);
        final idx = y * imageSize + x;

        // R 채널
        input[idx] = ((pixel.r / 255.0) - mean[0]) / std[0];
        // G 채널
        input[imageSize * imageSize + idx] =
            ((pixel.g / 255.0) - mean[1]) / std[1];
        // B 채널
        input[2 * imageSize * imageSize + idx] =
            ((pixel.b / 255.0) - mean[2]) / std[2];
      }
    }

    return input;
  }

  /// 임베딩 정규화 (L2 normalization)
  static List<double> _normalizeEmbedding(List<double> embedding) {
    final magnitude = sqrt(
      embedding.fold<double>(0.0, (sum, val) => sum + val * val),
    );

    if (magnitude > 0) {
      return embedding.map((val) => val / magnitude).toList();
    }
    return embedding;
  }

  /// 이미지를 임베딩 벡터로 변환
  /// URL에서 이미지를 다운로드하고 임베딩 생성
  Future<List<double>> getImageEmbeddingFromUrl(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        debugPrint('✅ 이미지 다운로드 성공: ${response.bodyBytes.length} bytes');
        return await getImageEmbedding(response.bodyBytes);
      } else {
        debugPrint('  - 응답 본문 전체:\n${response.body}');
        throw Exception('이미지 다운로드 실패 (Status ${response.statusCode})');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ getImageEmbeddingFromUrl 에러:');
      debugPrint('  - URL: $imageUrl');
      debugPrint('  - 에러: $e');
      debugPrint('  - 스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 공개 API: 이미지 임베딩 생성 (Worker Isolate에서 처리)
  Future<List<double>> getImageEmbedding(Uint8List imageBytes) async {
    if (!isModelReady) {
      throw Exception('모델이 준비되지 않았습니다. 현재 상태: $_status');
    }

    try {
      debugPrint('🔄 이미지 임베딩 생성 시작 (크기: ${imageBytes.length} bytes)');
      final response = await _sendRequest(
        IsolateRequestType.processImage,
        {'imageBytes': imageBytes},
      );

      if (!response.success) {
        throw Exception(response.error ?? '이미지 임베딩 생성 실패');
      }

      final embedding = List<double>.from(response.result as List);
      debugPrint('✅ 이미지 임베딩 생성 완료 (차원: ${embedding.length})');
      return embedding;
    } catch (e, stackTrace) {
      debugPrint('❌ getImageEmbedding 에러:');
      debugPrint('  - 이미지 크기: ${imageBytes.length} bytes');
      debugPrint('  - 모델 상태: $_status');
      debugPrint('  - 에러: $e');
      debugPrint('  - 스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 텍스트를 토큰으로 변환 (간단한 CLIP tokenizer)
  static Int64List _tokenizeText(String text) {
    // 간단한 토큰화 (실제로는 CLIP BPE tokenizer 사용해야 함)
    // 여기서는 placeholder로 구현

    // 소문자 변환 및 공백으로 분리
    final words = text.toLowerCase().split(RegExp(r'\s+'));

    // 간단한 vocab (실제로는 49408개의 vocab 필요)
    // 여기서는 ASCII 기반 간단한 매핑
    final tokens = <int>[49406]; // [CLS] 토큰

    for (var word in words) {
      if (tokens.length >= maxTokens - 1) break;

      // 간단한 해시 기반 토큰 ID (실제로는 BPE 필요)
      for (var i = 0; i < word.length && tokens.length < maxTokens - 1; i++) {
        tokens.add(word.codeUnitAt(i) % 49408);
      }
    }

    tokens.add(49407); // [SEP] 토큰

    // 패딩
    while (tokens.length < maxTokens) {
      tokens.add(0); // [PAD] 토큰
    }

    return Int64List.fromList(tokens.take(maxTokens).toList());
  }

  /// 텍스트를 임베딩 벡터로 변환 (Worker Isolate에서 처리)
  Future<List<double>> getTextEmbedding(String text) async {
    if (!isModelReady) {
      throw Exception('모델이 준비되지 않았습니다. 현재 상태: $_status');
    }

    try {
      debugPrint('🔄 텍스트 임베딩 생성 시작 (길이: ${text.length} chars)');
      final response = await _sendRequest(
        IsolateRequestType.processText,
        {'text': text},
      );

      if (!response.success) {
        throw Exception(response.error ?? '텍스트 임베딩 생성 실패');
      }

      final embedding = List<double>.from(response.result as List);
      debugPrint('✅ 텍스트 임베딩 생성 완료 (차원: ${embedding.length})');
      return embedding;
    } catch (e, stackTrace) {
      debugPrint('❌ getTextEmbedding 에러:');
      debugPrint('  - 텍스트: "$text"');
      debugPrint('  - 모델 상태: $_status');
      debugPrint('  - 에러: $e');
      debugPrint('  - 스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 코사인 유사도 계산 (0~1 범위)
  double calculateSimilarity(List<double> emb1, List<double> emb2) {
    if (emb1.length != emb2.length) {
      throw ArgumentError('임베딩 차원이 일치하지 않습니다');
    }

    // 정규화된 벡터의 내적 = 코사인 유사도
    double dotProduct = 0.0;
    for (var i = 0; i < emb1.length; i++) {
      dotProduct += emb1[i] * emb2[i];
    }

    // [-1, 1] 범위를 [0, 1]로 변환
    return (dotProduct + 1.0) / 2.0;
  }

  /// 텍스트로 이미지 검색
  Future<List<SimilarImageResult>> searchByText(
    String query,
    Map<int, List<double>> galleryEmbeddings,
  ) async {
    if (!isModelReady) {
      throw Exception('모델이 준비되지 않았습니다. 현재 상태: $_status');
    }

    try {
      debugPrint('🔍 텍스트 검색 시작: "$query" (갤러리 ${galleryEmbeddings.length}개)');
      
      // 텍스트 임베딩 생성
      final textEmb = await getTextEmbedding(query);

      // 모든 갤러리와 유사도 계산
      final results = <SimilarImageResult>[];

      for (var entry in galleryEmbeddings.entries) {
        final similarity = calculateSimilarity(textEmb, entry.value);
        results.add(SimilarImageResult(
          id: entry.key,
          similarity: similarity,
        ));
      }

      // 유사도 높은 순으로 정렬
      results.sort((a, b) => b.similarity.compareTo(a.similarity));

      debugPrint('✅ 텍스트 검색 완료: ${results.length}개 결과');
      return results;
    } catch (e, stackTrace) {
      debugPrint('❌ searchByText 에러:');
      debugPrint('  - 쿼리: "$query"');
      debugPrint('  - 갤러리 개수: ${galleryEmbeddings.length}');
      debugPrint('  - 에러: $e');
      debugPrint('  - 스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 유사한 이미지 찾기
  List<SimilarImageResult> findSimilarImages(
    List<double> queryEmbedding,
    Map<int, List<double>> galleryEmbeddings, {
    int topK = 10,
    double minSimilarity = 0.5,
  }) {
    final results = <SimilarImageResult>[];

    for (var entry in galleryEmbeddings.entries) {
      final similarity = calculateSimilarity(queryEmbedding, entry.value);

      if (similarity >= minSimilarity) {
        results.add(SimilarImageResult(
          id: entry.key,
          similarity: similarity,
        ));
      }
    }

    // 유사도 높은 순으로 정렬
    results.sort((a, b) => b.similarity.compareTo(a.similarity));

    // topK개만 반환
    return results.take(topK).toList();
  }

  /// 사용자 취향 기반 추천도 계산
  /// 즐겨찾기 갤러리들의 평균 임베딩과 비교
  Future<double> calculateRecommendationScore(
    String thumbnailUrl,
    Map<int, List<double>> favoriteEmbeddings,
  ) async {
    if (favoriteEmbeddings.isEmpty) {
      return 0.0; // 즐겨찾기가 없으면 추천도 0
    }

    try {
      // 썸네일 이미지로 임베딩 생성
      final thumbnailEmbedding = await getImageEmbeddingFromUrl(thumbnailUrl);

      // 즐겨찾기 갤러리들의 평균 임베딩 계산
      final avgEmbedding = _calculateAverageEmbedding(
        favoriteEmbeddings.values.toList(),
      );

      // 유사도 계산 (0-1 범위)
      final rawSimilarity =
          calculateSimilarity(thumbnailEmbedding, avgEmbedding);

      // 점수를 더 엄격하게 조정 (비선형 매핑)
      // 0.5 이하는 거의 0에 가깝게, 0.9 이상만 높은 점수
      final adjustedScore = _adjustScore(rawSimilarity);

      debugPrint('✅ 추천도 계산: $adjustedScore (원본 유사도: $rawSimilarity)');
      return adjustedScore;
    } catch (e, stackTrace) {
      debugPrint('❌ calculateRecommendationScore 에러:');
      debugPrint('  - 썸네일 URL: $thumbnailUrl');
      debugPrint('  - 즐겨찾기 개수: ${favoriteEmbeddings.length}');
      debugPrint('  - 에러: $e');
      debugPrint('  - 스택 트레이스: $stackTrace');
      return 0.0;
    }
  }

  /// 점수를 비선형으로 조정하여 변별력 향상
  /// 원본 범위: 0.0 ~ 1.0
  /// 조정 후: 더 엄격한 분포
  double _adjustScore(double rawScore) {
    // 0.5 미만은 거의 0으로
    if (rawScore < 0.5) {
      return 0.0;
    }

    // 0.5-1.0 범위를 0-1로 재매핑
    final normalized = (rawScore - 0.5) * 2.0;

    // 제곱을 사용하여 더 엄격하게 (변별력 증가)
    // 0.5 → 0.0
    // 0.7 → 0.16 (40^2 = 16)
    // 0.8 → 0.36 (60^2 = 36)
    // 0.9 → 0.64 (80^2 = 64)
    // 1.0 → 1.0  (100^2 = 100)
    return pow(normalized, 1.8).toDouble().clamp(0.0, 1.0);
  }

  /// 여러 임베딩의 평균 계산
  List<double> _calculateAverageEmbedding(List<List<double>> embeddings) {
    if (embeddings.isEmpty) {
      return List.filled(embeddingDim, 0.0);
    }

    final avgEmbedding = List<double>.filled(embeddingDim, 0.0);

    for (var embedding in embeddings) {
      for (var i = 0; i < embeddingDim; i++) {
        avgEmbedding[i] += embedding[i];
      }
    }

    // 평균 계산
    for (var i = 0; i < embeddingDim; i++) {
      avgEmbedding[i] /= embeddings.length;
    }

    // 정규화
    final magnitude = sqrt(avgEmbedding.fold<double>(
      0.0,
      (sum, val) => sum + val * val,
    ));

    if (magnitude > 0) {
      for (var i = 0; i < avgEmbedding.length; i++) {
        avgEmbedding[i] /= magnitude;
      }
    }

    return avgEmbedding;
  }

  /// 중복 이미지 찾기
  Map<int, List<int>> findDuplicates(
    Map<int, List<double>> galleryEmbeddings, {
    double similarityThreshold = 0.95,
  }) {
    final duplicates = <int, List<int>>{};
    final processed = <int>{};
    final ids = galleryEmbeddings.keys.toList();

    for (var i = 0; i < ids.length; i++) {
      final id1 = ids[i];
      if (processed.contains(id1)) continue;

      final group = <int>[];

      for (var j = i + 1; j < ids.length; j++) {
        final id2 = ids[j];
        if (processed.contains(id2)) continue;

        final similarity = calculateSimilarity(
          galleryEmbeddings[id1]!,
          galleryEmbeddings[id2]!,
        );

        if (similarity >= similarityThreshold) {
          if (group.isEmpty) {
            group.add(id1);
          }
          group.add(id2);
          processed.add(id2);
        }
      }

      if (group.isNotEmpty) {
        duplicates[id1] = group;
        processed.add(id1);
      }
    }

    return duplicates;
  }

  /// 리소스 정리
  @override
  void dispose() {
    // Worker Isolate 종료
    if (_workerIsolate != null) {
      try {
        _sendRequest(IsolateRequestType.dispose, {}).timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            debugPrint('⚠️  Isolate dispose 타임아웃');
            return IsolateResponse(id: '', success: true);
          },
        );
      } catch (e) {
        debugPrint('⚠️  Isolate dispose 실패: $e');
      }

      _workerIsolate!.kill(priority: Isolate.immediate);
      _workerIsolate = null;
    }

    _mainReceivePort?.close();
    _mainReceivePort = null;
    _workerSendPort = null;
    _pendingRequests.clear();

    super.dispose();
  }

  /// Worker Isolate 진입점
  static void _isolateEntryPoint(Map<String, dynamic> params) async {
    final mainSendPort = params['sendPort'] as SendPort;
    final visionModelBytes = params['visionModelData'] as Uint8List;
    final textModelBytes = params['textModelData'] as Uint8List;

    // Worker의 ReceivePort 생성
    final workerReceivePort = ReceivePort();

    // 메인 스레드에 Worker의 SendPort 전송
    mainSendPort.send(workerReceivePort.sendPort);

    // ONNX 세션 (Isolate 내부에서만 사용)
    OrtSession? visionSession;
    OrtSession? textSession;

    try {
      // 메시지 수신 및 처리 루프
      await for (final message in workerReceivePort) {
        if (message is! IsolateRequest) continue;

        final request = message;
        IsolateResponse response;

        try {
          switch (request.type) {
            case IsolateRequestType.initialize:
              // 모델 초기화
              try {
                debugPrint('[Worker] PE-Core 모델 로드 시작...');

                // Vision Encoder 로드
                final visionSessionOptions = OrtSessionOptions();
                try {
                  visionSessionOptions.appendDefaultProviders();
                  debugPrint('[Worker] ✅ GPU 가속 활성화 (Vision)');
                } catch (e) {
                  debugPrint('[Worker] ⚠️  GPU 가속 실패, CPU 사용 (Vision): $e');
                }

                visionSession = OrtSession.fromBuffer(
                  visionModelBytes,
                  visionSessionOptions,
                );

                debugPrint('[Worker] ✅ Vision Encoder 로드 완료');

                // Text Encoder 로드
                final textSessionOptions = OrtSessionOptions();
                try {
                  textSessionOptions.appendDefaultProviders();
                  debugPrint('[Worker] ✅ GPU 가속 활성화 (Text)');
                } catch (e) {
                  debugPrint('[Worker] ⚠️  GPU 가속 실패, CPU 사용 (Text): $e');
                }

                textSession = OrtSession.fromBuffer(
                  textModelBytes,
                  textSessionOptions,
                );

                debugPrint('[Worker] ✅ Text Encoder 로드 완료');
                debugPrint('[Worker] ✅ PE-Core 모델 초기화 완료');

                response = IsolateResponse(
                  id: request.id,
                  success: true,
                );
              } catch (e) {
                debugPrint('[Worker] ❌ 모델 초기화 실패: $e');
                response = IsolateResponse(
                  id: request.id,
                  success: false,
                  error: e.toString(),
                );
              }
              break;

            case IsolateRequestType.processImage:
              // 이미지 임베딩 생성
              try {
                if (visionSession == null) {
                  throw Exception('Vision 모델이 로드되지 않았습니다');
                }

                final imageBytes = request.data['imageBytes'] as Uint8List;

                // 이미지 전처리
                final input = _preprocessImage(imageBytes);

                // ONNX Runtime 입력 생성
                final inputOrt = OrtValueTensor.createTensorWithDataList(
                  input,
                  [1, 3, imageSize, imageSize],
                );

                // 추론
                final inputs = {visionSession.inputNames.first: inputOrt};
                final outputs = visionSession.run(
                  OrtRunOptions(),
                  inputs,
                );

                // 출력 추출
                final embedding = (outputs[0]?.value as List<List<double>>)[0];

                // 정리
                inputOrt.release();
                for (var output in outputs) {
                  output?.release();
                }

                // 벡터 정규화
                final normalized = _normalizeEmbedding(embedding);

                response = IsolateResponse(
                  id: request.id,
                  success: true,
                  result: normalized,
                );
              } catch (e) {
                debugPrint('[Worker] ❌ 이미지 임베딩 생성 실패: $e');
                response = IsolateResponse(
                  id: request.id,
                  success: false,
                  error: e.toString(),
                );
              }
              break;

            case IsolateRequestType.processText:
              // 텍스트 임베딩 생성
              try {
                if (textSession == null) {
                  throw Exception('Text 모델이 로드되지 않았습니다');
                }

                final text = request.data['text'] as String;

                // 텍스트 토큰화
                final tokens = _tokenizeText(text);

                // ONNX Runtime 입력 생성
                final inputOrt = OrtValueTensor.createTensorWithDataList(
                  tokens,
                  [1, maxTokens],
                );

                // 추론
                final inputs = {textSession.inputNames.first: inputOrt};
                final outputs = textSession.run(
                  OrtRunOptions(),
                  inputs,
                );

                // 출력 추출
                final embedding = (outputs[0]?.value as List<List<double>>)[0];

                // 정리
                inputOrt.release();
                for (var output in outputs) {
                  output?.release();
                }

                // 벡터 정규화
                final normalized = _normalizeEmbedding(embedding);

                response = IsolateResponse(
                  id: request.id,
                  success: true,
                  result: normalized,
                );
              } catch (e) {
                debugPrint('[Worker] ❌ 텍스트 임베딩 생성 실패: $e');
                response = IsolateResponse(
                  id: request.id,
                  success: false,
                  error: e.toString(),
                );
              }
              break;

            case IsolateRequestType.dispose:
              // 리소스 정리
              try {
                debugPrint('[Worker] 🧹 리소스 정리 중...');
                visionSession?.release();
                textSession?.release();
                visionSession = null;
                textSession = null;

                response = IsolateResponse(
                  id: request.id,
                  success: true,
                );

                mainSendPort.send(response);
                workerReceivePort.close();
                debugPrint('[Worker] ✅ Worker Isolate 종료');
                return; // Isolate 종료
              } catch (e) {
                debugPrint('[Worker] ⚠️  리소스 정리 실패: $e');
                response = IsolateResponse(
                  id: request.id,
                  success: false,
                  error: e.toString(),
                );
              }
              break;
          }
        } catch (e) {
          debugPrint('[Worker] ❌ 요청 처리 실패: $e');
          response = IsolateResponse(
            id: request.id,
            success: false,
            error: e.toString(),
          );
        }

        // 응답 전송
        mainSendPort.send(response);
      }
    } catch (e) {
      debugPrint('[Worker] ❌ Worker Isolate 크래시: $e');
      // 크래시 시 리소스 정리
      visionSession?.release();
      textSession?.release();
      workerReceivePort.close();
    }
  }
}
