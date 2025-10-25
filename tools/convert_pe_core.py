#!/usr/bin/env python3
"""
PE-Core-L14-336 모델을 TFLite로 변환하는 스크립트

필요한 패키지:
pip install torch torchvision transformers huggingface_hub onnx tf2onnx tensorflow

사용법:
python tools/convert_pe_core.py
"""

import os
import sys
import torch
import torch.nn as nn
import numpy as np
from pathlib import Path

# HuggingFace 토큰 설정 (환경 변수에서 가져오기)
HF_TOKEN = os.getenv("HF_TOKEN")
if not HF_TOKEN:
    print("⚠️  경고: HF_TOKEN 환경 변수가 설정되지 않았습니다.")
    print("HuggingFace 토큰이 필요한 경우 다음과 같이 설정하세요:")
    print("export HF_TOKEN=your_token_here")


def download_pe_core_model():
    """PE-Core-L14-336 모델 다운로드"""
    print("📦 PE-Core 모델 다운로드 중...")

    try:
        # perception_models 경로 추가
        perception_models_path = Path(__file__).parent / "perception_models"

        if not perception_models_path.exists():
            print("❌ perception_models 디렉토리를 찾을 수 없습니다.")
            print("\n다음 단계를 수행하세요:")
            print("1. cd tools")
            print(
                "2. git clone https://github.com/facebookresearch/perception_models.git"
            )
            print("3. cd perception_models")
            print("4. pip install -e .")
            sys.exit(1)

        sys.path.insert(0, str(perception_models_path))

        # PE-Core 모델 로드
        import core.vision_encoder.pe as pe

        print("모델 다운로드 중... (처음 실행 시 2.7GB 다운로드)")
        model = pe.CLIP.from_config("PE-Core-L14-336", pretrained=True)
        model.eval()

        # 모델 속성 확인 (디버깅)
        print("\n=== PE-Core 모델 속성 ===")
        print("모델 속성:", [attr for attr in dir(model) if not attr.startswith("_")])
        print("주요 속성:")
        for attr in [
            "visual",
            "text",
            "transformer",
            "token_embedding",
            "encode_text",
            "encode_image",
        ]:
            if hasattr(model, attr):
                print(f"  ✅ {attr}: {type(getattr(model, attr))}")
            else:
                print(f"  ❌ {attr}: 없음")
        print("========================\n")

        print("✅ 모델 다운로드 완료")
        return model
    except ImportError as e:
        print(f"❌ perception_models 임포트 실패: {e}")
        print("\nperception_models 설치:")
        print("cd tools/perception_models && pip install -e .")
        sys.exit(1)
    except Exception as e:
        print(f"❌ 모델 로드 실패: {e}")
        sys.exit(1)


def export_vision_encoder_to_onnx(model, output_path):
    """Vision Encoder를 ONNX로 변환"""
    print("\n🔄 Vision Encoder를 ONNX로 변환 중...")

    # Vision encoder 추출 (PE-Core는 visual 속성 사용)
    vision_encoder = model.visual
    vision_encoder.eval()

    # 더미 입력 (336x336x3, CHW 포맷)
    dummy_input = torch.randn(1, 3, 336, 336)

    # ONNX 내보내기
    torch.onnx.export(
        vision_encoder,
        dummy_input,
        output_path,
        export_params=True,
        opset_version=18,
        do_constant_folding=True,
        input_names=["image"],
        output_names=["vision_embedding"],  # 고유한 이름
        dynamic_axes={
            "image": {0: "batch_size"},
            "vision_embedding": {0: "batch_size"},
        },
    )

    print(f"✅ Vision Encoder ONNX 저장 완료: {output_path}")


def export_text_encoder_to_onnx(model, output_path):
    """Text Encoder를 ONNX로 변환"""
    print("\n🔄 Text Encoder를 ONNX로 변환 중...")

    # PE-Core의 context_length 확인
    context_length = getattr(model, "context_length", 32)
    print(f"  텍스트 컨텍스트 길이: {context_length}")

    # Text encoding을 위한 wrapper 생성
    class TextEncoderWrapper(torch.nn.Module):
        def __init__(self, clip_model):
            super().__init__()
            self.token_embedding = clip_model.token_embedding
            self.positional_embedding = clip_model.positional_embedding
            self.transformer = clip_model.transformer
            self.ln_final = clip_model.ln_final
            self.text_projection = clip_model.text_projection

        def forward(self, text):
            # PE-Core의 encode_text 로직 재구현
            x = self.token_embedding(text)
            x = x + self.positional_embedding[: text.shape[1]]
            x = x.permute(1, 0, 2)  # NLD -> LND
            x = self.transformer(x)
            x = x.permute(1, 0, 2)  # LND -> NLD
            x = self.ln_final(x)

            # 텍스트 임베딩 추출 (EOS 토큰 위치)
            x = x[torch.arange(x.shape[0]), text.argmax(dim=-1)] @ self.text_projection
            return x

    text_wrapper = TextEncoderWrapper(model)
    text_wrapper.eval()

    # 더미 입력 (컨텍스트 길이에 맞춤)
    dummy_input = torch.randint(0, model.vocab_size, (1, context_length))

    print("  텍스트 인코더 wrapper 생성 완료")

    # ONNX 내보내기
    torch.onnx.export(
        text_wrapper,
        dummy_input,
        output_path,
        export_params=True,
        opset_version=18,
        do_constant_folding=True,
        input_names=["tokens"],
        output_names=["text_embedding"],  # 고유한 이름
        dynamic_axes={"tokens": {0: "batch_size"}, "text_embedding": {0: "batch_size"}},
    )

    print(f"✅ Text Encoder ONNX 저장 완료: {output_path}")


def consolidate_onnx_model(onnx_path, quantize_fp16=True):
    """외부 데이터 파일을 ONNX 모델에 포함하고 float16으로 양자화"""
    import onnx
    from onnx import numpy_helper
    from pathlib import Path
    import numpy as np

    print(f"  처리 중: {onnx_path}")

    # ONNX 모델 로드 (외부 데이터 포함)
    model = onnx.load(onnx_path, load_external_data=True)

    # Float16 양자화
    if quantize_fp16:
        print(f"  🔄 Float16 양자화 중...")
        from onnxconverter_common import float16

        model = float16.convert_float_to_float16(
            model,
            keep_io_types=True,  # 입출력은 float32 유지
        )
        print(f"  ✅ Float16 양자화 완료 (크기 ~50% 감소)")

    # 외부 데이터를 내부로 통합하여 저장
    onnx.save(
        model,
        onnx_path,
        save_as_external_data=False,  # 외부 데이터 파일 사용 안 함
    )

    # 외부 데이터 파일 삭제
    data_file = Path(onnx_path).with_suffix(".onnx.data")
    if data_file.exists():
        data_file.unlink()

    # 파일 크기 확인
    file_size_mb = Path(onnx_path).stat().st_size / (1024 * 1024)
    print(f"  ✅ 최종 파일 크기: {file_size_mb:.1f} MB")


def convert_onnx_to_tflite(onnx_path, tflite_path, quantize=True):
    """ONNX 모델을 TFLite로 변환"""
    print(f"\n🔄 ONNX → TFLite 변환 중: {onnx_path}")

    try:
        import onnx
        import tensorflow as tf
        from onnx_tf.backend import prepare

        # ONNX 모델 로드
        onnx_model = onnx.load(onnx_path)

        # TensorFlow로 변환
        tf_rep = prepare(onnx_model)

        # SavedModel로 저장
        temp_dir = str(Path(tflite_path).parent / "temp_saved_model")
        tf_rep.export_graph(temp_dir)

        # TFLite로 변환
        converter = tf.lite.TFLiteConverter.from_saved_model(temp_dir)

        if quantize:
            # Float16 양자화
            converter.optimizations = [tf.lite.Optimize.DEFAULT]
            converter.target_spec.supported_types = [tf.float16]
            print("  📉 Float16 양자화 적용")

        tflite_model = converter.convert()

        # TFLite 모델 저장
        with open(tflite_path, "wb") as f:
            f.write(tflite_model)

        # 임시 디렉토리 삭제
        import shutil

        shutil.rmtree(temp_dir, ignore_errors=True)

        # 파일 크기 확인
        size_mb = os.path.getsize(tflite_path) / (1024 * 1024)
        print(f"✅ TFLite 변환 완료: {tflite_path} ({size_mb:.2f} MB)")

    except ImportError as e:
        print(f"❌ 필요한 패키지가 설치되지 않았습니다: {e}")
        print("다음 명령어로 설치하세요:")
        print("pip install onnx onnx-tf tensorflow")
        sys.exit(1)


def main():
    """메인 함수"""
    print("=" * 60)
    print("PE-Core-L14-336 TFLite 변환 스크립트")
    print("=" * 60)

    # 출력 디렉토리 생성
    output_dir = Path(__file__).parent.parent / "assets" / "models"
    output_dir.mkdir(parents=True, exist_ok=True)

    temp_dir = Path(__file__).parent / "temp"
    temp_dir.mkdir(exist_ok=True)

    try:
        # 1. 모델 다운로드
        model = download_pe_core_model()

        # 2. Vision Encoder → ONNX
        vision_onnx_path = temp_dir / "pe_core_vision_l14.onnx"
        export_vision_encoder_to_onnx(model, str(vision_onnx_path))

        # 3. Text Encoder → ONNX
        text_onnx_path = temp_dir / "pe_core_text_l14.onnx"
        export_text_encoder_to_onnx(model, str(text_onnx_path))

        # 4. 외부 데이터 파일을 모델에 포함 (양자화 비활성화)
        print("\n🔄 외부 데이터를 ONNX 파일에 통합 중...")
        consolidate_onnx_model(str(vision_onnx_path), quantize_fp16=False)
        consolidate_onnx_model(str(text_onnx_path), quantize_fp16=False)

        print("\n" + "=" * 60)
        print("✅ ONNX 변환 완료!")
        print("=" * 60)
        print(f"Vision Encoder: {vision_onnx_path}")
        print(f"Text Encoder: {text_onnx_path}")

        # TFLite 변환은 건너뛰고 ONNX Runtime 사용
        print("\n⚠️  TFLite 변환은 onnx-tf 호환성 문제로 건너뜁니다.")
        print("대신 ONNX Runtime for Flutter를 사용합니다.")
        print("\n📝 다음 단계:")
        print("1. ONNX 파일을 assets/models/로 복사:")
        print(f"   cp {temp_dir}/pe_core_vision_l14.onnx ../assets/models/")
        print(f"   cp {temp_dir}/pe_core_text_l14.onnx ../assets/models/")
        print("2. Flutter 프로젝트에서 'flutter pub get' 실행")
        print("3. 앱을 빌드하고 실행하세요")

    except Exception as e:
        print(f"\n❌ 오류 발생: {e}")
        import traceback

        traceback.print_exc()
        sys.exit(1)
    # finally 블록 제거 - ONNX 파일을 보존하기 위해


if __name__ == "__main__":
    main()
