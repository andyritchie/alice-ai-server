#!/bin/bash
# ============================================
# Download essential ComfyUI models
# ============================================

MODELS=~/ai-server/comfyui/models

echo "========================================"
echo "  Downloading ComfyUI Models"
echo "========================================"

# Create directories
mkdir -p $MODELS/{checkpoints,vae,loras,controlnet,upscale_models,embeddings}

# Checkpoints
echo -e "\n=== Checkpoints ===\n"
echo "Downloading SDXL Base (6.5GB)..."
wget -nc -P $MODELS/checkpoints \
  "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors" || true

# VAE
echo -e "\n=== VAE ===\n"
echo "Downloading SDXL VAE..."
wget -nc -P $MODELS/vae \
  "https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors" || true

# Upscalers
echo -e "\n=== Upscalers ===\n"
echo "Downloading Real-ESRGAN 4x..."
wget -nc -P $MODELS/upscale_models \
  "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth" || true

echo -e "\n========================================"
echo "  Download complete!"
echo "========================================"

echo -e "\nInstalled models:"
ls -lh $MODELS/checkpoints/ 2>/dev/null || echo "  No checkpoints"
ls -lh $MODELS/vae/ 2>/dev/null || echo "  No VAE"
ls -lh $MODELS/upscale_models/ 2>/dev/null || echo "  No upscalers"

echo -e "\nRestart ComfyUI to load new models:"
echo "  docker compose restart comfyui"
