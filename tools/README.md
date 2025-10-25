# PE-Core 모델 변환 가이드

이 디렉토리에는 PE-Core-L14-336 모델을 TFLite로 변환하는 스크립트가 포함되어 있습니다.

## 사전 준비

### 1. Python 환경 설정

```bash
# Python 3.8 이상 필요
python3 --version

# 가상 환경 생성 (권장)
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
```

### 2. 필수 패키지 설치

**macOS / CPU 전용 환경:**

```bash
# PyTorch CPU 버전 설치
pip install torch torchvision torchaudio

# 변환 도구 설치
pip install transformers huggingface_hub onnx onnx-tf tensorflow

# FFmpeg 설치 (Homebrew 사용)
brew install ffmpeg
```

**Linux with CUDA (선택):**

```bash
pip install torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 --index-url https://download.pytorch.org/whl/cu124
pip install transformers huggingface_hub onnx onnx-tf tensorflow
sudo apt install ffmpeg  # 또는 conda install ffmpeg -c conda-forge
```

### 3. Perception Models 레포지토리 클론

```bash
cd tools
git clone https://github.com/facebookresearch/perception_models.git
cd perception_models

# macOS 환경용 의존성 설치
pip install -e .

# torchcodec는 선택사항 (비디오 처리 시에만 필요)
# 현재는 이미지만 사용하므로 스킵 가능

cd ..
```

## 모델 변환 실행

```bash
python convert_pe_core.py
```

변환이 완료되면 다음 파일들이 생성됩니다:

- `../assets/models/pe_core_vision_l14.tflite` (~160MB, float16 양자화)
- `../assets/models/pe_core_text_l14.tflite` (~155MB, float16 양자화)

## 문제 해결

### ONNX 변환 실패

PE-Core 모델 구조가 복잡하여 ONNX 변환이 실패할 수 있습니다. 이 경우:

1. **직접 TFLite 변환**: PyTorch → TensorFlow → TFLite
2. **사전 변환된 모델 사용**: HuggingFace에서 TFLite 버전 찾기

### 대안: 간단한 CLIP 모델 사용

PE-Core 변환이 어려운 경우, OpenAI CLIP ViT-B/32를 사용할 수 있습니다:

```bash
# 더 작고 변환하기 쉬운 모델
pip install clip
python convert_clip_vit_b32.py
```

## 모델 크기 최적화

양자화 옵션:

- `float16`: ~50% 크기 감소, 성능 손실 미미
- `int8`: ~75% 크기 감소, 약간의 성능 손실
- `dynamic range`: 가변 양자화

스크립트 내 `quantize=True` 옵션으로 조정 가능합니다.
