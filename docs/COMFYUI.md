# ComfyUI Setup & Usage

## Overview

ComfyUI is your local image generation powerhouse. Alice can use it for:
- Image generation ("create an image of...")
- Image-to-image transformations
- Video generation (with AnimateDiff)
- Upscaling
- Background removal
- Style transfer

## Accessing ComfyUI

**Web UI:** http://ai-server:8188

## Installing Models

### Checkpoint Models (Main image generators)

```bash
# SSH into server
ssh user@ai-server

# Navigate to models folder
cd ~/ai-server/comfyui/models/checkpoints

# Download SDXL (recommended starting point)
wget https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors

# Download SDXL Refiner (optional, improves quality)
wget https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0/resolve/main/sd_xl_refiner_1.0.safetensors

# Download Flux (newer, better quality - needs more VRAM)
# Get from civitai.com or huggingface
```

### LoRA Models (Style/character adapters)

```bash
cd ~/ai-server/comfyui/models/loras

# Download from civitai.com or huggingface
# Example: detail enhancer
wget [lora-url] -O detail_enhancer.safetensors
```

### VAE Models

```bash
cd ~/ai-server/comfyui/models/vae

# SDXL VAE
wget https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors
```

### ControlNet Models

```bash
cd ~/ai-server/comfyui/models/controlnet

# Depth ControlNet for SDXL
wget https://huggingface.co/diffusers/controlnet-depth-sdxl-1.0/resolve/main/diffusion_pytorch_model.safetensors -O controlnet-depth-sdxl.safetensors
```

### Upscale Models

```bash
cd ~/ai-server/comfyui/models/upscale_models

# 4x upscaler
wget https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth
```

## Model Download Script

Add to `scripts/download-comfyui-models.sh`:

```bash
#!/bin/bash
# Download essential ComfyUI models

MODELS_DIR=~/ai-server/comfyui/models

echo "Downloading SDXL Base..."
wget -P $MODELS_DIR/checkpoints https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors

echo "Downloading SDXL VAE..."
wget -P $MODELS_DIR/vae https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors

echo "Downloading Upscaler..."
wget -P $MODELS_DIR/upscale_models https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth

echo "Done! Restart ComfyUI to load new models."
```

## Using ComfyUI with Alice

### API Endpoints

ComfyUI exposes a REST API:

```bash
# Queue a prompt
POST http://ai-server:8188/prompt

# Get queue status
GET http://ai-server:8188/queue

# Get generated images
GET http://ai-server:8188/view?filename=output.png
```

### Alice Integration Script

Create `scripts/comfyui-generate.js`:

```javascript
const fetch = require('node-fetch');

async function generateImage(prompt, options = {}) {
    const workflow = {
        // Basic SDXL workflow
        "3": {
            "class_type": "KSampler",
            "inputs": {
                "seed": Math.floor(Math.random() * 1000000),
                "steps": options.steps || 20,
                "cfg": options.cfg || 7,
                "sampler_name": "euler",
                "scheduler": "normal",
                "denoise": 1,
                "model": ["4", 0],
                "positive": ["6", 0],
                "negative": ["7", 0],
                "latent_image": ["5", 0]
            }
        },
        "4": {
            "class_type": "CheckpointLoaderSimple",
            "inputs": {
                "ckpt_name": options.model || "sd_xl_base_1.0.safetensors"
            }
        },
        "5": {
            "class_type": "EmptyLatentImage",
            "inputs": {
                "width": options.width || 1024,
                "height": options.height || 1024,
                "batch_size": 1
            }
        },
        "6": {
            "class_type": "CLIPTextEncode",
            "inputs": {
                "text": prompt,
                "clip": ["4", 1]
            }
        },
        "7": {
            "class_type": "CLIPTextEncode",
            "inputs": {
                "text": options.negative || "blurry, bad quality, distorted",
                "clip": ["4", 1]
            }
        },
        "8": {
            "class_type": "VAEDecode",
            "inputs": {
                "samples": ["3", 0],
                "vae": ["4", 2]
            }
        },
        "9": {
            "class_type": "SaveImage",
            "inputs": {
                "filename_prefix": "alice",
                "images": ["8", 0]
            }
        }
    };

    const response = await fetch('http://ai-server:8188/prompt', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ prompt: workflow })
    });

    return response.json();
}

module.exports = { generateImage };
```

### Voice Command Examples

```
"Alice, generate an image of a sunset over mountains"
"Alice, create a picture of a cute robot bunny"
"Alice, make me a logo for a coffee shop"
```

## Workflow Templates

### Text-to-Image (Basic)
Load the default workflow, works out of the box.

### Image-to-Image
1. Load image via "Load Image" node
2. Connect to "VAE Encode"
3. Use in KSampler with denoise < 1.0

### Upscaling
1. Load image
2. Connect to upscale model
3. Save output

### ControlNet (Pose/Depth)
1. Load reference image
2. Run through ControlNet preprocessor
3. Feed to ControlNet Apply node
4. Use with KSampler

## Performance Tips

- **Batch size 1** for fastest single images
- **Steps 20-30** is usually enough for SDXL
- **CFG 7-8** for balanced quality
- Use **fp16** for faster generation with minimal quality loss
- **Xformers** enabled by default in Docker image

## Troubleshooting

### Out of VRAM
- Reduce image size (768x768 instead of 1024x1024)
- Use `--lowvram` flag
- Close other GPU processes

### Slow generation
- Check GPU utilization with `nvtop`
- Ensure CUDA is being used (not CPU)
- Use optimized model variants (fp16)

### Model not loading
- Check file path is correct
- Ensure file isn't corrupted (re-download)
- Check ComfyUI logs: `docker logs comfyui`
