#!/bin/bash
set -e

# ============================================
# Alice AI Server - Main Setup Script
# ============================================
# Run this on a fresh Ubuntu Server 22.04/24.04
# Usage: ./setup.sh
# ============================================

echo "=========================================="
echo "  Alice AI Server Setup"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}Please don't run as root. Run as your normal user.${NC}"
    exit 1
fi

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${YELLOW}Step 1/7: System Update${NC}"
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git htop nvtop tmux

echo -e "${YELLOW}Step 2/7: NVIDIA Drivers${NC}"
# Check if NVIDIA GPU exists
if lspci | grep -i nvidia > /dev/null; then
    echo "NVIDIA GPU detected, installing drivers..."
    sudo apt install -y nvidia-driver-550 nvidia-utils-550
    echo -e "${GREEN}NVIDIA drivers installed. Reboot required after setup.${NC}"
else
    echo -e "${RED}No NVIDIA GPU detected. Some features will not work.${NC}"
fi

echo -e "${YELLOW}Step 3/7: Docker${NC}"
# Install Docker
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    echo -e "${GREEN}Docker installed. Log out and back in for group changes.${NC}"
else
    echo "Docker already installed"
fi

# Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    sudo apt install -y docker-compose-plugin
fi

echo -e "${YELLOW}Step 4/7: NVIDIA Container Toolkit${NC}"
if lspci | grep -i nvidia > /dev/null; then
    # Add NVIDIA container toolkit repo
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    sudo apt update
    sudo apt install -y nvidia-container-toolkit
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
fi

echo -e "${YELLOW}Step 5/7: Create directories${NC}"
mkdir -p ~/ai-server/{ollama,whisper,piper,comfyui,models}
mkdir -p ~/ai-server/comfyui/{models,output,input}

echo -e "${YELLOW}Step 6/7: Pull Docker images${NC}"
# Copy docker-compose.yml
cp "$SCRIPT_DIR/docker-compose.yml" ~/ai-server/

cd ~/ai-server

# Pull images (but don't start yet)
docker compose pull

echo -e "${YELLOW}Step 7/7: Start services${NC}"
docker compose up -d

echo ""
echo -e "${GREEN}=========================================="
echo "  Setup Complete!"
echo "==========================================${NC}"
echo ""
echo "Services running:"
echo "  • Ollama:        http://$(hostname -I | awk '{print $1}'):11434"
echo "  • Whisper API:   http://$(hostname -I | awk '{print $1}'):8080"
echo "  • Piper TTS:     http://$(hostname -I | awk '{print $1}'):5000"
echo "  • ComfyUI:       http://$(hostname -I | awk '{print $1}'):8188"
echo "  • Open WebUI:    http://$(hostname -I | awk '{print $1}'):3000"
echo "  • Portainer:     http://$(hostname -I | awk '{print $1}'):9000"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Reboot to load NVIDIA drivers: sudo reboot"
echo "  2. After reboot, pull models: ./scripts/pull-models.sh"
echo "  3. Configure OpenClaw to use this server"
echo ""
echo -e "${YELLOW}To check GPU:${NC} nvidia-smi"
echo -e "${YELLOW}To check services:${NC} docker compose ps"
echo -e "${YELLOW}To view logs:${NC} docker compose logs -f [service]"
