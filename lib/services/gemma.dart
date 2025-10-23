import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:http/http.dart' as http;

enum ImageQuality { thumbnail, original }

enum ModelStatus {
  notInstalled,
  downloading,
  installed,
  error,
}

class GemmaService extends ChangeNotifier {
  static final GemmaService _instance = GemmaService._internal();
  factory GemmaService() => _instance;
  GemmaService._internal();

  ModelStatus _status = ModelStatus.notInstalled;
  double _downloadProgress = 0.0;
  String? _errorMessage;
  dynamic _model;
  dynamic _chat;

  ModelStatus get status => _status;
  double get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;
  bool get isModelReady => _status == ModelStatus.installed && _model != null;

  // Gemma 3 Nano 4B 모델 URL (HuggingFace)
  static const String modelUrl =
      'https://huggingface.co/google/gemma-3-nano-e4b-it/resolve/main/gemma-3-nano-e4b-it-gpu-int8.task';

  /// 모델 다운로드 및 설치
  Future<void> downloadModel({Function(double)? onProgress}) async {
    try {
      _status = ModelStatus.downloading;
      _downloadProgress = 0.0;
      _errorMessage = null;
      notifyListeners();

      // 모델 다운로드 및 설치
      // ModelType.gemmaIt를 사용 (.task 파일이 실제 모델 타입 결정)
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
      ).fromNetwork(modelUrl).withProgress((progress) {
        _downloadProgress = (progress as double? ?? 0.0);
        onProgress?.call(_downloadProgress);
        notifyListeners();
      }).install();

      _status = ModelStatus.installed;
      _downloadProgress = 1.0;
      notifyListeners();

      // 모델 초기화
      await _initializeModel();
    } catch (e) {
      _status = ModelStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// 모델 초기화
  Future<void> _initializeModel() async {
    if (_model != null) {
      return; // 이미 초기화됨
    }

    try {
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 2048,
        preferredBackend: PreferredBackend.gpu,
      );
    } catch (e) {
      debugPrint('모델 초기화 실패: $e');
      rethrow;
    }
  }

  /// 설치된 모델 확인
  Future<void> checkModelStatus() async {
    try {
      // 설치된 모델 확인
      final models = await FlutterGemma.listInstalledModels();
      if (models.isNotEmpty) {
        _status = ModelStatus.installed;
        await _initializeModel();
      } else {
        _status = ModelStatus.notInstalled;
      }
      notifyListeners();
    } catch (e) {
      _status = ModelStatus.notInstalled;
      notifyListeners();
    }
  }

  /// 모델 삭제
  Future<void> deleteModel() async {
    try {
      // Flutter Gemma API에서 deleteModel이 없을 수 있으므로 상태만 리셋
      _status = ModelStatus.notInstalled;
      _model = null;
      _chat = null;
      notifyListeners();
    } catch (e) {
      debugPrint('모델 삭제 실패: $e');
      rethrow;
    }
  }

  /// 이미지 분석
  Future<String> analyzeImage(
    String imageUrl, {
    ImageQuality quality = ImageQuality.thumbnail,
  }) async {
    if (!isModelReady) {
      throw Exception('모델이 준비되지 않았습니다.');
    }

    try {
      // 이미지 다운로드
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('이미지 다운로드 실패: ${response.statusCode}');
      }

      final imageBytes = response.bodyBytes;

      // 채팅 세션 생성 (multimodal 지원)
      _chat ??= await _model!.createChat(supportImage: true);

      // 이미지와 함께 프롬프트 전송
      await _chat!.addQueryChunk(Message.withImage(
        text:
            'Describe this image in detail. Focus on the visual content, style, composition, and any notable elements. Be specific and descriptive.',
        isUser: true,
        imageBytes: imageBytes,
      ));

      // 응답 생성
      final response2 = await _chat!.generateChatResponse();
      return response2;
    } catch (e) {
      debugPrint('이미지 분석 실패: $e');
      rethrow;
    }
  }

  /// 텍스트 임베딩 생성
  Future<List<double>> getTextEmbedding(String text) async {
    // 간단한 텍스트 임베딩 (단어 빈도 기반)
    // 실제로는 더 정교한 임베딩 모델을 사용할 수 있습니다
    // flutter_gemma에서 EmbeddingGemma를 사용할 수도 있습니다

    // 단어 분리 및 정규화
    final words = text.toLowerCase().split(RegExp(r'\W+'));
    final wordFreq = <String, double>{};

    for (var word in words) {
      if (word.isNotEmpty) {
        wordFreq[word] = (wordFreq[word] ?? 0) + 1;
      }
    }

    // 간단한 임베딩: 상위 100개 단어의 빈도를 벡터로 변환
    final embedding = List<double>.filled(100, 0.0);
    var index = 0;
    for (var entry in wordFreq.entries.take(100)) {
      if (index < 100) {
        embedding[index] = entry.value;
        index++;
      }
    }

    // 벡터 정규화
    final magnitude = sqrt(embedding.fold<double>(
        0.0, (sum, value) => sum + value * value));
    if (magnitude > 0) {
      for (var i = 0; i < embedding.length; i++) {
        embedding[i] /= magnitude;
      }
    }

    return embedding;
  }

  /// 코사인 유사도 계산
  double calculateSimilarity(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) {
      throw Exception('임베딩 벡터의 길이가 다릅니다.');
    }

    double dotProduct = 0.0;
    double magnitude1 = 0.0;
    double magnitude2 = 0.0;

    for (var i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      magnitude1 += embedding1[i] * embedding1[i];
      magnitude2 += embedding2[i] * embedding2[i];
    }

    magnitude1 = sqrt(magnitude1);
    magnitude2 = sqrt(magnitude2);

    if (magnitude1 == 0 || magnitude2 == 0) {
      return 0.0;
    }

    return dotProduct / (magnitude1 * magnitude2);
  }

  /// 채팅 세션 정리
  Future<void> clearChat() async {
    try {
      await _chat?.close();
      _chat = null;
    } catch (e) {
      debugPrint('채팅 세션 정리 실패: $e');
    }
  }

  @override
  void dispose() {
    _chat?.close();
    _model?.close();
    super.dispose();
  }
}

