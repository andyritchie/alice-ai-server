# Windows Setup Guide

Complete setup guide for running Alice AI Server on Windows.

## Prerequisites

- Windows 10/11 Pro (for Hyper-V) or Home (with WSL2)
- NVIDIA GPU with latest drivers
- 32GB+ RAM recommended
- 500GB+ SSD

## Step 1: Install NVIDIA Drivers

1. Go to https://www.nvidia.com/drivers
2. Download latest Game Ready or Studio driver for your GPU
3. Install and restart

**Verify:**
```powershell
nvidia-smi
```
Should show your GPU and driver version.

## Step 2: Install Docker Desktop

1. Download from https://www.docker.com/products/docker-desktop/
2. Run installer
3. **Important:** During install, ensure "Use WSL 2 instead of Hyper-V" is checked
4. Restart computer
5. Open Docker Desktop
6. Go to Settings → Resources → WSL Integration → Enable for your distro

**Verify:**
```powershell
docker --version
docker run hello-world
```

## Step 3: Enable GPU in Docker

1. Open Docker Desktop
2. Settings → Docker Engine
3. Add to the JSON config:
```json
{
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "runtimeArgs": []
    }
  }
}
```
4. Apply & Restart

**Verify:**
```powershell
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi
```
Should show your GPU inside the container.

## Step 4: Create Project Folder

```powershell
# Open PowerShell as Administrator
mkdir C:\AI-Server
cd C:\AI-Server
mkdir ollama, whisper, piper, comfyui, models, voices
```

## Step 5: Create Docker Compose File

Create `C:\AI-Server\docker-compose.yml`:

```yaml
version: '3.8'

services:
  # Ollama - Local LLM
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    environment:
      - OLLAMA_HOST=0.0.0.0
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]

  # Open WebUI - Chat Interface
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    restart: unless-stopped
    ports:
      - "3000:8080"
    volumes:
      - open_webui_data:/app/backend/data
    environment:
      - OLLAMA_BASE_URL=http://ollama:11434
      - WEBUI_AUTH=false
    depends_on:
      - ollama

  # Whisper - Speech to Text
  whisper:
    image: fedirz/faster-whisper-server:latest-cuda
    container_name: whisper
    restart: unless-stopped
    ports:
      - "8080:8000"
    environment:
      - WHISPER__MODEL=Systran/faster-whisper-large-v3-turbo
      - WHISPER__DEVICE=cuda
      - WHISPER__COMPUTE_TYPE=float16
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]

  # Piper - Text to Speech
  piper:
    image: rhasspy/wyoming-piper:latest
    container_name: piper
    restart: unless-stopped
    ports:
      - "10200:10200"
    command: --voice en_US-amy-medium
    volumes:
      - piper_data:/data

  # Portainer - Container Management GUI
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    ports:
      - "9000:9000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data

volumes:
  ollama_data:
  open_webui_data:
  piper_data:
  portainer_data:
```

## Step 6: Start Services

```powershell
cd C:\AI-Server
docker compose up -d
```

**Watch the logs:**
```powershell
docker compose logs -f
```

Press `Ctrl+C` to exit logs.

## Step 7: Pull LLM Models

```powershell
# Fast model (5GB)
docker exec ollama ollama pull llama3.2:8b

# Vision model (8GB)
docker exec ollama ollama pull llava:13b

# Smart model - only if you have 24GB+ VRAM (20GB)
docker exec ollama ollama pull qwen2.5:32b

# List installed models
docker exec ollama ollama list
```

## Step 8: Install ComfyUI (Standalone)

ComfyUI works better as a standalone install on Windows:

1. Download from https://github.com/comfyanonymous/ComfyUI/releases
2. Extract to `C:\AI-Server\ComfyUI`
3. Run `run_nvidia_gpu.bat`
4. Access at http://localhost:8188

### Download ComfyUI Models

```powershell
cd C:\AI-Server\ComfyUI\models\checkpoints

# Download SDXL Base
Invoke-WebRequest -Uri "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors" -OutFile "sd_xl_base_1.0.safetensors"
```

Or just download manually from https://huggingface.co and put in the models folder.

## Step 9: Verify Everything Works

### Check containers are running:
```powershell
docker ps
```

### Test Ollama:
```powershell
curl http://localhost:11434/api/generate -d '{\"model\":\"llama3.2:8b\",\"prompt\":\"Hello\",\"stream\":false}'
```

Or just open http://localhost:3000 in your browser (Open WebUI).

### Test Whisper:
```powershell
curl http://localhost:8080/health
```

## Access URLs

| Service | URL |
|---------|-----|
| Open WebUI (Chat) | http://localhost:3000 |
| ComfyUI | http://localhost:8188 |
| Portainer (Container GUI) | http://localhost:9000 |
| Ollama API | http://localhost:11434 |
| Whisper API | http://localhost:8080 |
| Piper TTS | http://localhost:10200 |

## Daily Operations

### Start all services:
```powershell
cd C:\AI-Server
docker compose up -d
```

### Stop all services:
```powershell
docker compose down
```

### Restart a service:
```powershell
docker compose restart ollama
```

### View logs:
```powershell
docker compose logs -f ollama
```

### Update containers:
```powershell
docker compose pull
docker compose up -d
```

## Using Portainer (GUI Management)

1. Open http://localhost:9000
2. Create admin account on first visit
3. Click "Get Started"
4. Click "local" environment

From here you can:
- See all running containers
- View logs (click container → Logs)
- Restart containers (click container → Restart)
- Check resource usage

**This is your GUI alternative to command line!**

## Troubleshooting

### Container won't start
1. Open Portainer (http://localhost:9000)
2. Click the container
3. Click "Logs" to see error messages

### GPU not detected in Docker
1. Open Docker Desktop
2. Settings → Resources → WSL Integration
3. Make sure it's enabled
4. Restart Docker Desktop

### Out of disk space
1. Docker Desktop → Settings → Resources → Disk
2. Increase disk size
3. Or run: `docker system prune -a` (removes unused images)

### Ollama model download stuck
```powershell
# Check progress
docker logs ollama

# If stuck, restart and retry
docker compose restart ollama
docker exec ollama ollama pull llama3.2:8b
```

## Accessing from Other Devices

Your services are accessible from other devices on your network at:
- `http://YOUR-PC-NAME:3000` (Open WebUI)
- `http://YOUR-PC-NAME:11434` (Ollama API)

Find your PC name:
```powershell
hostname
```

Or your IP:
```powershell
ipconfig
```

## Auto-Start on Boot

Docker Desktop can be set to start on login:
1. Docker Desktop → Settings → General
2. Enable "Start Docker Desktop when you sign in to Windows"

Containers with `restart: unless-stopped` will auto-start when Docker starts.

## Next Steps

1. ✅ Services running
2. → Configure OpenClaw to use local models
3. → Set up Voice PE integration
4. → Train "Alice" wake word
