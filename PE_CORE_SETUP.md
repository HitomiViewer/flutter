# PE-Core-L14-336 설정 가이드

이 문서는 PE-Core-L14-336 모델을 Flutter 앱에서 사용하기 위한 설정 가이드입니다.

## 📋 개요

PE-Core-L14-336은 Facebook Research의 최신 CLIP 기반 모델로, 다음 기능을 제공합니다:

- **이미지 임베딩**: 336x336px 이미지를 1024차원 벡터로 변환
- **텍스트 임베딩**: 32 토큰 텍스트를 1024차원 벡터로 변환
- **이미지 유사도 검색**: 비슷한 이미지 찾기
- **텍스트 기반 이미지 검색**: "애니메이션 소녀"와 같은 텍스트로 이미지 검색

## 🔧 모델 변환 (필수)

Flutter 앱에서 사용하려면 먼저 PyTorch 모델을 TFLite로 변환해야 합니다.

### 1단계: Python 환경 설정

```bash
# Python 3.8 이상 필요
python3 --version

# 프로젝트 루트로 이동
cd /Users/rmagur1203/Projects/Private/flutter

# 가상 환경 생성 (권장)
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
```

### 2단계: 필수 패키지 설치

```bash
# PyTorch 및 의존성 설치
pip install torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 --index-url https://download.pytorch.org/whl/cu124

# 변환 도구 설치
pip install transformers huggingface_hub onnx onnx-tf tensorflow

# FFmpeg 설치 (macOS)
brew install ffmpeg
```

### 3단계: Perception Models 설치

```bash
cd tools
git clone https://github.com/facebookresearch/perception_models.git
cd perception_models

# 의존성 설치
pip install xformers --index-url https://download.pytorch.org/whl/cu124
pip install torchcodec==0.1 --index-url=https://download.pytorch.org/whl/cu124
pip install -e .

cd ..
```

### 4단계: 모델 변환 실행

```bash
# tools 디렉토리에서 실행
python convert_pe_core.py
```

변환이 완료되면 다음 파일이 생성됩니다:

- `assets/models/pe_core_vision_l14.tflite` (~160MB)
- `assets/models/pe_core_text_l14.tflite` (~155MB)

## 📱 Flutter 앱 빌드

모델 변환이 완료되면 Flutter 앱을 빌드할 수 있습니다:

```bash
# 프로젝트 루트로 이동
cd /Users/rmagur1203/Projects/Private/flutter

# 의존성 설치
flutter pub get

# Android 빌드
flutter build apk --debug

# iOS 빌드 (macOS만)
flutter build ios
```

## 🎯 사용 방법

### 앱 시작 시

앱이 시작되면 자동으로 PE-Core 모델을 로드합니다. `assets/models/` 디렉토리에 모델 파일이 없으면 오류가 표시됩니다.

### 설정 화면

1. **설정** → **이미지 분석** 이동
2. **PE-Core-L14-336** 타일 확인:
   - ✅ 녹색 체크: 모델 로드 완료
   - ⚠️ 빨간 느낌표: 모델 로드 실패 (변환 필요)
   - ⏳ 모래시계: 로딩 중

### 배치 분석

1. **설정** → **이미지 분석** → **좋아요 갤러리 분석**
2. 분석 시작하면 각 이미지를 1024차원 벡터로 변환
3. 임베딩은 자동으로 로컬 저장

### 텍스트 검색 (예정)

```dart
// 예시 코드
final results = await ImageEmbeddingService().searchByText(
  "anime girl with blue hair",
  store.galleryEmbeddings,
);
```

## 🔧 문제 해결

### 모델 로드 실패

**증상**: 설정에서 "로드 실패" 표시

**해결**:

1. `assets/models/` 디렉토리에 파일이 있는지 확인
2. 파일 이름 확인:
   - `pe_core_vision_l14.tflite`
   - `pe_core_text_l14.tflite`
3. 모델을 다시 변환하고 앱 재빌드

### 변환 실패

**증상**: `python convert_pe_core.py` 실행 시 오류

**해결**:

1. Python 버전 확인 (3.8 이상)
2. 모든 의존성이 설치되었는지 확인
3. CUDA가 없는 경우 CPU 버전 사용:
   ```bash
   pip install torch torchvision torchaudio
   ```

### APK 크기

모델 번들링으로 APK 크기가 약 320MB 증가합니다.

**최적화 옵션**:

- int8 양자화: ~75% 크기 감소, 약간의 정확도 손실
- 다운로드 방식: APK는 작지만 첫 실행 시 다운로드 필요

## 📊 성능

### 모델 크기

- Vision Encoder: ~160MB (float16)
- Text Encoder: ~155MB (float16)
- 총합: ~315MB

### 추론 속도 (예상)

- 이미지 임베딩: ~100-200ms (CPU)
- 텍스트 임베딩: ~50-100ms (CPU)
- GPU 가속 시 2-5배 빠름

### 정확도

- ImageNet-1k: 83.5%
- ObjectNet: 84.7%
- 애니메이션/일러스트: 우수

## 🔄 G 모델로 업그레이드

나중에 더 큰 PE-Core-G14-448 모델로 업그레이드하려면:

1. `convert_pe_core.py`에서 모델 이름 변경:

   ```python
   model = pe.CLIP.from_config("PE-Core-G14-448", pretrained=True)
   ```

2. 이미지 크기 변경 (336 → 448):

   ```dart
   static const int imageSize = 448;
   ```

3. 임베딩 차원 변경 (1024 → 1280):

   ```dart
   static const int embeddingDim = 1280;
   ```

4. 모델 재변환 및 앱 재빌드

## 📚 참고 자료

- [PE-Core 논문](https://arxiv.org/abs/2504.13181)
- [PE-Core GitHub](https://github.com/facebookresearch/perception_models)
- [HuggingFace 모델 페이지](https://huggingface.co/facebook/PE-Core-L14-336)

## ❓ FAQ

**Q: 모델 변환이 너무 오래 걸립니다.**
A: 첫 실행 시 모델 다운로드에 시간이 걸립니다 (~630MB). 이후 실행은 빠릅니다.

**Q: CUDA가 없는데 변환할 수 있나요?**
A: 네, CPU로도 변환 가능합니다. 단, 속도가 느릴 수 있습니다.

**Q: 텍스트 토크나이저가 정확하지 않은 것 같습니다.**
A: 현재는 간단한 토크나이저를 사용합니다. 정확한 CLIP BPE tokenizer는 추후 업데이트 예정입니다.

**Q: 기존 임베딩 데이터는 어떻게 되나요?**
A: PE-Core는 512차원 → 1024차원으로 변경되어 기존 데이터와 호환되지 않습니다. 재분석이 필요합니다.
