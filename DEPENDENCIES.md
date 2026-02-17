# Dependencies & Requirements

## AI Server (Ubuntu)

### System Requirements
- **OS:** Ubuntu Server 22.04 LTS or 24.04 LTS
- **GPU:** NVIDIA RTX 3090/4090 (24GB VRAM recommended)
- **RAM:** 32GB minimum, 64GB recommended
- **Storage:** 500GB+ SSD (models are large)
- **Network:** Gigabit ethernet recommended

### Software (installed by setup.sh)
- NVIDIA Driver 550+
- CUDA Toolkit 12.x
- Docker CE
- Docker Compose
- NVIDIA Container Toolkit

### Docker Images
| Image | Purpose | Size |
|-------|---------|------|
| ollama/ollama | LLM inference | ~2GB |
| ghcr.io/open-webui/open-webui | Chat UI | ~1GB |
| fedirz/faster-whisper-server | STT | ~4GB |
| rhasspy/wyoming-piper | TTS | ~500MB |
| yanwk/comfyui-boot | Image gen | ~5GB |
| portainer/portainer-ce | Management | ~300MB |

### Models (downloaded separately)
| Model | Size | Purpose |
|-------|------|---------|
| llama3.2:8b | ~5GB | Fast queries |
| qwen2.5:7b | ~5GB | Fast queries |
| qwen2.5:32b | ~20GB | Smart local |
| llava:13b | ~8GB | Vision |
| qwen2.5-coder:7b | ~5GB | Coding |
| nomic-embed-text | ~300MB | Embeddings |
| Whisper large-v3 | ~3GB | STT |
| Piper en_US-amy | ~100MB | TTS |

**Total storage needed:** ~60-100GB for models

---

## Home Assistant

### Required Addons
- ESPHome
- Piper (optional, backup TTS)
- Whisper (optional, backup STT)
- openWakeWord

### Required Integrations
- Cast (for Google speakers)
- Media Player
- Wyoming Protocol

### HACS Components (optional)
- Extended OpenAI Conversation
- Music Assistant

---

## Voice PE

### Hardware
- Home Assistant Voice Preview Edition
- USB-C power supply (5V 2A)
- Optional: 3.5mm speaker cable

### Firmware
- Open Voice PE custom firmware
  - GitHub: https://github.com/mike-nott/open-voice-pe

### Wake Word
- Custom trained `alice.tflite` model
- Training: Google Colab notebook

---

## OpenClaw (Main PC)

### Requirements
- Node.js 20+
- OpenClaw CLI installed
- Network access to AI server

### Config Changes
- Enable HTTP API endpoint
- Enable webhooks
- Configure Ollama provider
- Configure local STT/TTS endpoints

---

## Network

### Ports Used
| Service | Port | Location |
|---------|------|----------|
| OpenClaw Gateway | 18789 | Main PC |
| Ollama | 11434 | AI Server |
| Whisper | 8080 | AI Server |
| Piper | 10200 | AI Server |
| ComfyUI | 8188 | AI Server |
| Open WebUI | 3000 | AI Server |
| Portainer | 9000 | AI Server |
| Home Assistant | 8123 | HA Host |
| ESPHome | 6052 | HA Host |

### Recommended Network Setup
- All devices on same LAN subnet
- Static IPs for servers
- Or use Tailscale for secure access

---

## Cloud Services (Optional)

### Still Used
| Service | Purpose | Cost |
|---------|---------|------|
| Anthropic Claude | Complex tasks | ~$20/mo |
| ElevenLabs | Voice TTS | $22/mo |

### Can Be Replaced Locally
| Cloud Service | Local Alternative |
|---------------|-------------------|
| OpenAI GPT | Ollama + Llama/Qwen |
| Whisper API | Faster-Whisper |
| Cloud TTS | Piper |
| DALL-E | ComfyUI + SDXL |

---

## Quick Checklist

### AI Server Setup
- [ ] Ubuntu Server installed
- [ ] NVIDIA drivers working (`nvidia-smi`)
- [ ] Docker installed
- [ ] Docker Compose installed
- [ ] NVIDIA Container Toolkit installed
- [ ] All containers running
- [ ] Models downloaded

### Home Assistant Setup
- [ ] ESPHome addon installed
- [ ] openWakeWord addon installed
- [ ] Voice PE adopted in ESPHome
- [ ] Custom firmware flashed
- [ ] Wake word model installed

### OpenClaw Setup
- [ ] HTTP API enabled
- [ ] Ollama provider configured
- [ ] Local STT configured
- [ ] Webhooks enabled (optional)

### Testing
- [ ] Can reach Ollama from main PC
- [ ] Can reach Whisper from HA
- [ ] Wake word triggers on Voice PE
- [ ] Full voice command works end-to-end
