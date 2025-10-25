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

  // PE-Core 모델 (Vision + Text)
  OrtSession? _visionSession;
  OrtSession? _textSession;

  ModelStatus _status = ModelStatus.notLoaded;
  String? _errorMessage;

  ModelStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isModelReady => _status == ModelStatus.loaded;

  // 모델 설정
  static const int imageSize = 336; // PE-Core-L14는 336x336
  static const int embeddingDim = 1024; // PE-Core-L14는 1024차원
  static const int maxTokens = 32; // CLIP 텍스트 최대 토큰 수

  // 🚀 동시 실행 제한 (UI 블로킹 방지)
  static const int _maxConcurrentInferences = 3; // 최대 3개까지 동시 실행
  int _runningInferences = 0;

  /// 앱 시작 시 모델 로드
  Future<void> initialize() async {
    try {
      _status = ModelStatus.loading;
      _errorMessage = null;
      notifyListeners();

      debugPrint('PE-Core ONNX 모델 로드 중...');

      // Vision Encoder 로드
      try {
        final visionModelData = await rootBundle.load(
          'assets/models/pe_core_vision_l14.onnx',
        );

        final sessionOptions = OrtSessionOptions();

        // 🚀 GPU 가속 자동 활성화!
        // CUDA → DirectML → ROCm → CoreML → NNAPI → CPU 순으로 자동 선택
        try {
          sessionOptions.appendDefaultProviders();
          debugPrint('✅ GPU 가속 활성화');
        } catch (e) {
          debugPrint('⚠️  GPU 가속 실패, CPU 사용: $e');
        }

        _visionSession = OrtSession.fromBuffer(
          visionModelData.buffer.asUint8List(),
          sessionOptions,
        );

        debugPrint('✅ Vision Encoder 로드 완료');
        _logSessionInfo(_visionSession!, 'Vision');
      } catch (e) {
        debugPrint('⚠️  Vision Encoder 로드 실패: $e');
        throw Exception('Vision 모델을 찾을 수 없습니다. '
            'tools/README.md를 참고하여 모델을 변환하고 assets/models/에 추가하세요.');
      }

      // Text Encoder 로드
      try {
        final textModelData = await rootBundle.load(
          'assets/models/pe_core_text_l14.onnx',
        );

        final sessionOptions = OrtSessionOptions();

        // 🚀 GPU 가속 자동 활성화!
        try {
          sessionOptions.appendDefaultProviders();
          debugPrint('✅ GPU 가속 활성화');
        } catch (e) {
          debugPrint('⚠️  GPU 가속 실패, CPU 사용: $e');
        }

        _textSession = OrtSession.fromBuffer(
          textModelData.buffer.asUint8List(),
          sessionOptions,
        );

        debugPrint('✅ Text Encoder 로드 완료');
        _logSessionInfo(_textSession!, 'Text');
      } catch (e) {
        debugPrint('⚠️  Text Encoder 로드 실패: $e');
        throw Exception('Text 모델을 찾을 수 없습니다. '
            'tools/README.md를 참고하여 모델을 변환하고 assets/models/에 추가하세요.');
      }

      _status = ModelStatus.loaded;
      debugPrint('✅ PE-Core 모델 초기화 완료');
      notifyListeners();
    } catch (e) {
      _status = ModelStatus.error;
      _errorMessage = e.toString();
      debugPrint('❌ 모델 초기화 실패: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// 모델 정보 로깅
  void _logSessionInfo(OrtSession session, String name) {
    debugPrint('=== $name Encoder 정보 ===');
    debugPrint('입력:');
    for (var input in session.inputNames) {
      debugPrint('  - $input');
    }
    debugPrint('출력:');
    for (var output in session.outputNames) {
      debugPrint('  - $output');
    }
    debugPrint('====================');
  }

  /// 이미지 전처리 (PE-Core: 336x336, ImageNet 정규화)
  /// 백그라운드에서 실행 가능한 독립 함수
  static Float32List _preprocessImage(Uint8List imageBytes) {
    // 이미지 디코딩
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('이미지 디코딩 실패');
    }

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
  List<double> _normalizeEmbedding(List<double> embedding) {
    final magnitude = sqrt(
      embedding.fold<double>(0.0, (sum, val) => sum + val * val),
    );

    if (magnitude > 0) {
      return embedding.map((val) => val / magnitude).toList();
    }
    return embedding;
  }

  /// 큐 기반 추론 실행 (동시 실행 제한)
  Future<T> _runInferenceWithQueue<T>(Future<T> Function() task) async {
    // 현재 실행 중인 작업이 최대치를 초과하면 대기
    while (_runningInferences >= _maxConcurrentInferences) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _runningInferences++;
    try {
      return await task();
    } finally {
      _runningInferences--;
      debugPrint('🔄 추론 완료 (실행 중: $_runningInferences)');
    }
  }

  /// 이미지를 임베딩 벡터로 변환
  /// URL에서 이미지를 다운로드하고 임베딩 생성
  Future<List<double>> getImageEmbeddingFromUrl(String imageUrl) async {
    return _runInferenceWithQueue(() async {
      try {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          return await _getImageEmbeddingInternal(response.bodyBytes);
        } else {
          throw Exception('이미지 다운로드 실패: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('이미지 다운로드 실패: $e');
        rethrow;
      }
    });
  }

  /// 공개 API: 큐를 통한 이미지 임베딩 생성
  Future<List<double>> getImageEmbedding(Uint8List imageBytes) async {
    return _runInferenceWithQueue(() => _getImageEmbeddingInternal(imageBytes));
  }

  /// 내부 메서드: 실제 임베딩 생성 로직
  Future<List<double>> _getImageEmbeddingInternal(Uint8List imageBytes) async {
    if (!isModelReady) {
      throw Exception('모델이 준비되지 않았습니다.');
    }

    try {
      // 🚀 이미지 전처리를 백그라운드 isolate에서 수행 (UI 블로킹 방지)
      final input = await compute(_preprocessImage, imageBytes);

      // ONNX Runtime 입력 생성
      final inputOrt = OrtValueTensor.createTensorWithDataList(
        input,
        [1, 3, imageSize, imageSize],
      );

      // 추론
      final inputs = {_visionSession!.inputNames.first: inputOrt};
      final outputs = _visionSession!.run(
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
      return _normalizeEmbedding(embedding);
    } catch (e) {
      debugPrint('이미지 임베딩 생성 실패: $e');
      rethrow;
    }
  }

  /// 텍스트를 토큰으로 변환 (간단한 CLIP tokenizer)
  Int64List _tokenizeText(String text) {
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

  /// 텍스트를 임베딩 벡터로 변환
  Future<List<double>> getTextEmbedding(String text) async {
    if (!isModelReady) {
      throw Exception('모델이 준비되지 않았습니다.');
    }

    if (_textSession == null) {
      throw Exception('Text Encoder가 로드되지 않았습니다.');
    }

    try {
      // 텍스트 토큰화
      final tokens = _tokenizeText(text);

      // ONNX Runtime 입력 생성
      final inputOrt = OrtValueTensor.createTensorWithDataList(
        tokens,
        [1, maxTokens],
      );

      // 추론
      final inputs = {_textSession!.inputNames.first: inputOrt};
      final outputs = _textSession!.run(
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
      return _normalizeEmbedding(embedding);
    } catch (e) {
      debugPrint('텍스트 임베딩 생성 실패: $e');
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
      throw Exception('모델이 준비되지 않았습니다.');
    }

    try {
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

      return results;
    } catch (e) {
      debugPrint('텍스트 검색 실패: $e');
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

      return adjustedScore;
    } catch (e) {
      debugPrint('추천도 계산 실패: $e');
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
  void dispose() {
    _visionSession?.release();
    _textSession?.release();
    super.dispose();
  }
}
