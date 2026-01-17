import os
import subprocess

import modal

MODEL_ID = os.environ.get("MODEL_ID", "twhitworth/gpt-oss-120b-awq-w4a16")
SERVED_MODEL_NAME = os.environ.get("SERVED_MODEL_NAME", "gpt-oss-120b")
QUANTIZATION = os.environ.get("QUANTIZATION", "awq")
DTYPE = os.environ.get("DTYPE", "float16")
GPU_COUNT = int(os.environ.get("GPU_COUNT", "2"))
GPU_SIZE = os.environ.get("GPU_SIZE", "80GB")
GPU_TYPE = os.environ.get("GPU_TYPE", f"A100-{GPU_SIZE}")
MAX_MODEL_LEN = int(os.environ.get("MAX_MODEL_LEN", "8192"))
GPU_MEMORY_UTIL = os.environ.get("GPU_MEMORY_UTILIZATION", "0.90")
API_KEY = os.environ.get("MODAL_LLM_TOKEN", "")

image = (
    modal.Image.debian_slim()
    .pip_install(
        "vllm==0.6.4",
        "transformers==4.47.0",
        "accelerate",
        "huggingface_hub",
        "sentencepiece",
    )
)

volume = modal.Volume.from_name("homeos-llm-cache", create_if_missing=True)

app = modal.App("homeos-gpt-oss-120b")


@app.function(
    gpu=f"{GPU_TYPE}:{GPU_COUNT}",
    timeout=60 * 60,
    max_containers=1,
    volumes={"/models": volume},
    secrets=[modal.Secret.from_name("homeos-modal-llm")],
)
@modal.web_server(8000, startup_timeout=60 * 60)
def serve() -> None:
    env = os.environ.copy()
    env["HF_HOME"] = "/models/hf"
    env["TRANSFORMERS_CACHE"] = "/models/hf"
    env["HF_HUB_ENABLE_HF_TRANSFER"] = "1"

    command = [
        "python",
        "-m",
        "vllm.entrypoints.openai.api_server",
        "--host",
        "0.0.0.0",
        "--port",
        "8000",
        "--model",
        MODEL_ID,
        "--served-model-name",
        SERVED_MODEL_NAME,
        "--quantization",
        QUANTIZATION,
        "--dtype",
        DTYPE,
        "--tensor-parallel-size",
        str(GPU_COUNT),
        "--max-model-len",
        str(MAX_MODEL_LEN),
        "--gpu-memory-utilization",
        str(GPU_MEMORY_UTIL),
        "--enable-prefix-caching",
        "--trust-remote-code",
    ]
    if API_KEY:
        command += ["--api-key", API_KEY]

    subprocess.run(command, check=True, env=env)
