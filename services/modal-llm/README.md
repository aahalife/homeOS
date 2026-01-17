# Modal GPT-OSS 120B

This service deploys a **quantized** GPT-OSS 120B model on Modal using a vLLM
OpenAI-compatible server.

Default model:
- `twhitworth/gpt-oss-120b-awq-w4a16` (AWQ 4-bit weights)

## Local setup

```
python3 -m venv .modal-venv
.modal-venv/bin/pip install modal
.modal-venv/bin/modal token new
```

Complete the browser login flow shown by the CLI.

## Create an API key for the server

```
MODAL_LLM_TOKEN=$(openssl rand -hex 32)
.modal-venv/bin/modal secret create homeos-modal-llm MODAL_LLM_TOKEN="$MODAL_LLM_TOKEN"
```

Keep `MODAL_LLM_TOKEN` for Fly secrets later.

## Deploy

```
.modal-venv/bin/modal deploy modal_app.py
```

The deploy output will include the public web endpoint for the vLLM server.
Use that as `MODAL_LLM_URL`.

## Tuning

You can override defaults with environment variables:

- `MODEL_ID` (default `twhitworth/gpt-oss-120b-awq-w4a16`)
- `GPU_COUNT` (default `2`)
- `GPU_SIZE` (default `80GB`)
- `GPU_TYPE` (default `A100-80GB`)
- `MAX_MODEL_LEN` (default `8192`)
- `GPU_MEMORY_UTILIZATION` (default `0.90`)
- `QUANTIZATION` (default `awq`)
- `DTYPE` (default `float16`)
