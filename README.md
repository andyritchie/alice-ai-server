# Alice AI Server

Local AI infrastructure for the Alice home assistant system.

## Overview

This repo contains everything needed to set up a local AI server that powers:
- **Local LLM** (Ollama) - Fast responses, zero API costs
- **Local STT** (Faster-Whisper) - Speech-to-text
- **Local TTS** (Piper + voice clone) - Text-to-speech
- **Local Image Gen** (ComfyUI) - Image generation
- **Local Vision** (LLaVA) - Camera/image analysis

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         HOUSE                                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐     │
│   │Voice PE │    │Voice PE │    │Voice PE │    │Voice PE │     │
│   │ Office  │    │ Kitchen │    │ Bedroom │    │ Living  │     │
│   └────┬────┘    └────┬────┘    └────┬────┘    └────┬────┘     │
│        │              │              │              │           │
│        └──────────────┴──────────────┴──────────────┘           │
│                              │                                   │
│                              ▼                                   │
│                    ┌─────────────────┐                          │
│                    │ Home Assistant  │                          │
│                    │   (Whisper)     │                          │
│                    └────────┬────────┘                          │
│                             │                                    │
│              ┌──────────────┴──────────────┐                    │
│              ▼                              ▼                    │
│    ┌─────────────────┐            ┌─────────────────┐          │
│    │  Alice (Main)   │            │   AI Server     │          │
│    │    OpenClaw     │◄──────────►│   (Ubuntu)      │          │
│    │   Gateway       │            │                 │          │
│    │                 │            │ • Ollama (LLM)  │          │
│    │ • Claude API    │            │ • Whisper (STT) │          │
│    │ • ElevenLabs    │            │ • Piper (TTS)   │          │
│    │ • Tools/Skills  │            │ • ComfyUI       │          │
│    └────────┬────────┘            │ • LLaVA         │          │
│             │                      └─────────────────┘          │
│             ▼                                                    │
│    ┌─────────────────┐                                          │
│    │ Google Speakers │ (TTS output / Music)                     │
│    └─────────────────┘                                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Hardware Requirements

**AI Server (Recommended):**
- GPU: NVIDIA RTX 4090 / 3090 (24GB VRAM) or RTX 4080 (16GB)
- RAM: 32GB+ (64GB ideal)
- Storage: 1TB+ NVMe SSD
- CPU: Modern 8+ core (AMD Ryzen / Intel i7+)

**VRAM Usage Estimates:**
| Service | VRAM |
|---------|------|
| Ollama (Llama 3.3 70B Q4) | ~40GB |
| Ollama (Llama 3.3 8B) | ~6GB |
| Ollama (Qwen 2.5 32B Q4) | ~20GB |
| Faster-Whisper large-v3 | ~3GB |
| ComfyUI (SDXL) | ~8GB |
| LLaVA 13B | ~10GB |

## Quick Start

### 1. Fresh Ubuntu Server Install

```bash
# Download Ubuntu Server 22.04 LTS
# Create bootable USB with Rufus/Balena Etcher
# Install with minimal options, enable SSH
```

### 2. Run Setup Script

```bash
# SSH into server
ssh user@ai-server.local

# Clone this repo
git clone https://github.com/andyritchie/alice-ai-server.git
cd alice-ai-server

# Run setup (installs everything)
chmod +x setup.sh
./setup.sh
```

### 3. Configure OpenClaw

Copy the config template and update with your server IP:
```bash
cp configs/openclaw-ai-server.json ~/.openclaw/config.json
```

## Directory Structure

```
alice-ai-server/
├── README.md                 # This file
├── setup.sh                  # Main setup script
├── docker-compose.yml        # All services
├── configs/
│   ├── openclaw-ai-server.json   # OpenClaw config template
│   ├── ollama-models.txt         # Models to pull
│   └── piper-voices.txt          # TTS voices to download
├── scripts/
│   ├── install-nvidia.sh         # NVIDIA driver install
│   ├── install-docker.sh         # Docker setup
│   ├── install-ollama.sh         # Ollama setup
│   ├── install-whisper.sh        # Faster-Whisper setup
│   ├── install-piper.sh          # Piper TTS setup
│   ├── install-comfyui.sh        # ComfyUI setup
│   └── test-all.sh               # Test all services
├── voice-pe/
│   ├── README.md                 # Voice PE setup guide
│   ├── open-voice-pe.yaml        # Custom firmware config
│   └── alice-wakeword/           # Wake word model
├── home-assistant/
│   ├── README.md                 # HA integration guide
│   └── automations.yaml          # Voice command automations
└── docs/
    ├── ARCHITECTURE.md           # Detailed architecture
    ├── TROUBLESHOOTING.md        # Common issues
    └── MODELS.md                 # Model recommendations
```

## Services

### Ollama (Local LLM)
- **Port:** 11434
- **URL:** http://ai-server:11434
- **Models:** Llama 3.3, Qwen 2.5, Mistral, CodeLlama

### Faster-Whisper (STT)
- **Port:** 8080
- **URL:** http://ai-server:8080
- **Model:** large-v3-turbo

### Piper (TTS)
- **Port:** 5000
- **URL:** http://ai-server:5000
- **Voices:** en_US-amy-medium (or custom clone)

### ComfyUI (Image Gen)
- **Port:** 8188
- **URL:** http://ai-server:8188
- **Models:** SDXL, Flux

### Open WebUI (Chat Interface)
- **Port:** 3000
- **URL:** http://ai-server:3000
- **Purpose:** Web chat with local models

## OpenClaw Integration

### Enable HTTP API

Add to your OpenClaw config:
```json
{
  "gateway": {
    "http": {
      "endpoints": {
        "chatCompletions": { "enabled": true }
      }
    }
  }
}
```

### Model Routing

Configure OpenClaw to route based on task:
```json
{
  "agents": {
    "main": {
      "models": {
        "default": "anthropic/claude-sonnet-4-20250514",
        "fast": "ollama/llama3.3:8b",
        "local": "ollama/qwen2.5:32b"
      }
    }
  }
}
```

### Webhook for Voice Commands

```json
{
  "hooks": {
    "enabled": true,
    "token": "your-secret-token",
    "path": "/hooks"
  }
}
```

## Voice PE Integration

See [voice-pe/README.md](voice-pe/README.md) for:
- Flashing Open Voice PE firmware
- Custom "Alice" wake word setup
- Connecting to OpenClaw

## Home Assistant Integration

See [home-assistant/README.md](home-assistant/README.md) for:
- Assist pipeline configuration
- Media player routing
- Voice command automations

## Monitoring

Access Portainer for container management:
- **URL:** http://ai-server:9000

## Costs Saved (Monthly)

| Service | Cloud Cost | Local Cost |
|---------|-----------|------------|
| ElevenLabs TTS | $22/mo | $0 |
| Whisper API | ~$5/mo | $0 |
| Simple LLM queries | ~$20/mo | $0 |
| Image generation | ~$10/mo | $0 |
| **Total** | **~$57/mo** | **$0** |

Plus: Faster responses, full privacy, no rate limits.

## Roadmap

- [x] Project structure
- [ ] Setup scripts
- [ ] Docker Compose config
- [ ] Voice PE firmware
- [ ] Wake word training
- [ ] OpenClaw config templates
- [ ] Home Assistant integration
- [ ] Voice cloning setup
- [ ] Monitoring dashboard

## License

MIT
