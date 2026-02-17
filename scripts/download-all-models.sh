#!/bin/bash
# ============================================
# Download ALL models for Alice AI Server
# ============================================
# Run after setup.sh and reboot
# ============================================

set -e
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "========================================"
echo "  Alice AI Server - Download All Models"
echo "========================================"
echo ""
echo "This will download:"
echo "  • Ollama LLMs (~30-50GB)"
echo "  • Whisper STT (~3GB)"
echo "  • ComfyUI models (~10-20GB)"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Ollama models
echo -e "\n========================================"
echo "  1/3: Ollama LLM Models"
echo "========================================"
$SCRIPT_DIR/pull-models.sh

# Whisper model (auto-downloads on first use, but we can pre-warm)
echo -e "\n========================================"
echo "  2/3: Whisper STT Model"
echo "========================================"
echo "Whisper will download model on first use."
echo "Pre-warming by running a test transcription..."
docker exec whisper curl -s http://localhost:8000/health || echo "Whisper warming up..."

# ComfyUI models
echo -e "\n========================================"
echo "  3/3: ComfyUI Image Models"
echo "========================================"
$SCRIPT_DIR/download-comfyui-models.sh

echo ""
echo "========================================"
echo "  All Downloads Complete!"
echo "========================================"
echo ""
echo "Total disk usage:"
du -sh ~/ai-server/*/

echo ""
echo "Services should be ready to use!"
echo "Test with: curl http://localhost:11434/api/generate -d '{\"model\":\"llama3.2:8b\",\"prompt\":\"Hello\"}'"
