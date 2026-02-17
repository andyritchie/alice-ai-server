#!/bin/bash
# ============================================
# Pull recommended models for Ollama
# ============================================

echo "Pulling Ollama models..."
echo "This may take a while depending on your internet speed."
echo ""

# Fast models (for quick queries)
echo "=== Fast Models (8B) ==="
docker exec ollama ollama pull llama3.2:8b
docker exec ollama ollama pull qwen2.5:7b

# Smart models (for complex tasks) - only if you have 24GB+ VRAM
echo ""
echo "=== Smart Models (32B+) - Skip if <24GB VRAM ==="
read -p "Do you have 24GB+ VRAM? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker exec ollama ollama pull qwen2.5:32b
    docker exec ollama ollama pull deepseek-r1:32b
fi

# Coding models
echo ""
echo "=== Coding Models ==="
docker exec ollama ollama pull qwen2.5-coder:7b

# Vision models (for image analysis)
echo ""
echo "=== Vision Models ==="
docker exec ollama ollama pull llava:13b

# Embedding models (for RAG)
echo ""
echo "=== Embedding Models ==="
docker exec ollama ollama pull nomic-embed-text

echo ""
echo "=== Models installed ==="
docker exec ollama ollama list

echo ""
echo "Done! Test with: curl http://localhost:11434/api/generate -d '{\"model\":\"llama3.2:8b\",\"prompt\":\"Hello\"}'"
