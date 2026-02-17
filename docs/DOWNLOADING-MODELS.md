# Downloading Models

Complete guide for downloading all AI models needed for the Alice system.

## Ollama Models (LLM)

### Via Command Line

```bash
# SSH into AI server
ssh user@ai-server

# Pull models via Ollama CLI
docker exec ollama ollama pull llama3.2:8b      # Fast, general purpose
docker exec ollama ollama pull qwen2.5:7b       # Fast, good at following instructions
docker exec ollama ollama pull qwen2.5:32b      # Smart, needs 24GB+ VRAM
docker exec ollama ollama pull llava:13b        # Vision model
docker exec ollama ollama pull qwen2.5-coder:7b # Coding
docker exec ollama ollama pull nomic-embed-text # Embeddings for RAG

# List installed models
docker exec ollama ollama list
```

### Model Sizes

| Model | Download | VRAM (Q4) | Use Case |
|-------|----------|-----------|----------|
| llama3.2:3b | 2GB | 3GB | Very fast, simple tasks |
| llama3.2:8b | 5GB | 5GB | Fast, general purpose |
| qwen2.5:7b | 5GB | 5GB | Fast, instruction-following |
| qwen2.5:14b | 9GB | 10GB | Medium, good balance |
| qwen2.5:32b | 20GB | 20GB | Smart, complex reasoning |
| llama3.3:70b | 40GB | 40GB | Very smart, needs 48GB+ |
| llava:7b | 5GB | 6GB | Vision, basic |
| llava:13b | 8GB | 10GB | Vision, better quality |
| deepseek-r1:32b | 20GB | 22GB | Reasoning, thinking |

### Custom Model Files

If you have custom GGUF files:

```bash
# Create modelfile
cat > ~/Modelfile << 'EOF'
FROM ./my-model.gguf
PARAMETER temperature 0.7
PARAMETER num_ctx 4096
SYSTEM You are Alice, a helpful AI assistant.
EOF

# Import into Ollama
docker exec ollama ollama create my-model -f /root/Modelfile
```

## Whisper Models (STT)

The Docker image auto-downloads on first use, but you can pre-download:

```bash
# SSH into AI server
cd ~/ai-server

# Download Whisper models manually
docker exec whisper python -c "from faster_whisper import WhisperModel; WhisperModel('large-v3-turbo')"
```

### Model Options

| Model | Size | Speed | Accuracy |
|-------|------|-------|----------|
| tiny | 75MB | Very fast | Low |
| base | 150MB | Fast | OK |
| small | 500MB | Medium | Good |
| medium | 1.5GB | Slow | Better |
| large-v3 | 3GB | Slower | Best |
| large-v3-turbo | 3GB | Fast | Best (recommended) |

Change model in `docker-compose.yml`:
```yaml
environment:
  - WHISPER__MODEL=Systran/faster-whisper-large-v3-turbo
```

## Piper Voices (TTS)

### Pre-installed Voice

The Docker image comes with `en_US-amy-medium`.

### Download Additional Voices

```bash
# List available voices
curl -s https://huggingface.co/rhasspy/piper-voices/raw/main/VOICES.md | head -100

# Download a voice
cd ~/ai-server/piper_data
wget https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx
wget https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json
```

### Popular English Voices

| Voice | Style | Quality |
|-------|-------|---------|
| en_US-amy-medium | Female, neutral | Good |
| en_US-lessac-medium | Male, clear | Good |
| en_US-libritts_r-medium | Various | Good |
| en_GB-alan-medium | British male | Good |

### Change Voice

Update docker-compose.yml:
```yaml
piper:
  command: --voice en_US-lessac-medium
```

## ComfyUI Models (Image Gen)

### Directory Structure

```
~/ai-server/comfyui/models/
├── checkpoints/     # Main models (SD, SDXL, Flux)
├── loras/           # LoRA adapters
├── vae/             # VAE models
├── controlnet/      # ControlNet models
├── upscale_models/  # Upscalers
├── embeddings/      # Textual inversions
└── clip/            # CLIP models
```

### Essential Downloads

#### Checkpoints (Pick one to start)

```bash
cd ~/ai-server/comfyui/models/checkpoints

# SDXL Base (6.5GB) - Good starting point
wget https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors

# SDXL Lightning (Fast generation)
wget https://huggingface.co/ByteDance/SDXL-Lightning/resolve/main/sdxl_lightning_4step_unet.safetensors

# Juggernaut XL (Popular community model)
# Download from civitai.com
```

#### VAE

```bash
cd ~/ai-server/comfyui/models/vae

# SDXL VAE (fixes color issues)
wget https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors
```

#### Upscalers

```bash
cd ~/ai-server/comfyui/models/upscale_models

# Real-ESRGAN 4x
wget https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth

# 4x UltraSharp
# Download from openmodeldb.info
```

### Download Script

Create `scripts/download-comfyui-models.sh`:

```bash
#!/bin/bash

MODELS=~/ai-server/comfyui/models

echo "=== Downloading Checkpoints ==="
mkdir -p $MODELS/checkpoints
wget -nc -P $MODELS/checkpoints \
  https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors

echo "=== Downloading VAE ==="
mkdir -p $MODELS/vae
wget -nc -P $MODELS/vae \
  https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors

echo "=== Downloading Upscalers ==="
mkdir -p $MODELS/upscale_models
wget -nc -P $MODELS/upscale_models \
  https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth

echo "=== Done! ==="
ls -la $MODELS/*/
```

## Embedding Models (RAG)

For knowledge base / semantic search:

```bash
# Via Ollama
docker exec ollama ollama pull nomic-embed-text
docker exec ollama ollama pull mxbai-embed-large

# Test
curl http://localhost:11434/api/embeddings -d '{
  "model": "nomic-embed-text",
  "prompt": "Hello world"
}'
```

## Model Storage Requirements

| Category | Minimum | Recommended |
|----------|---------|-------------|
| Ollama LLMs | 20GB | 100GB |
| Whisper | 3GB | 3GB |
| Piper TTS | 1GB | 2GB |
| ComfyUI | 20GB | 100GB |
| **Total** | **44GB** | **205GB** |

Recommend: 500GB+ NVMe SSD for comfortable expansion.

## Download All Script

Master script `scripts/download-all-models.sh`:

```bash
#!/bin/bash
set -e

echo "========================================"
echo "  Downloading All Models for Alice AI"
echo "========================================"

# Ollama models
echo -e "\n=== Ollama Models ===\n"
./scripts/pull-models.sh

# Whisper (auto-downloads on first use)
echo -e "\n=== Whisper Model ===\n"
docker exec whisper python -c "from faster_whisper import WhisperModel; WhisperModel('large-v3-turbo')" || true

# ComfyUI
echo -e "\n=== ComfyUI Models ===\n"
./scripts/download-comfyui-models.sh

echo -e "\n========================================"
echo "  All models downloaded!"
echo "========================================"
```
