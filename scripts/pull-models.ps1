# ============================================
# Pull Ollama Models - Windows PowerShell
# ============================================
# Run this after docker compose is running
# ============================================

Write-Host "========================================"
Write-Host "  Pulling Ollama Models"
Write-Host "========================================"
Write-Host ""

# Check if Ollama container is running
$ollama = docker ps --filter "name=ollama" --format "{{.Names}}"
if (-not $ollama) {
    Write-Host "ERROR: Ollama container is not running!" -ForegroundColor Red
    Write-Host "Start it first: docker compose up -d"
    exit 1
}

Write-Host "Pulling fast model (llama3.2:8b)..." -ForegroundColor Yellow
docker exec ollama ollama pull llama3.2:8b

Write-Host ""
Write-Host "Pulling coding model (qwen2.5-coder:7b)..." -ForegroundColor Yellow
docker exec ollama ollama pull qwen2.5-coder:7b

Write-Host ""
Write-Host "Pulling vision model (llava:13b)..." -ForegroundColor Yellow
docker exec ollama ollama pull llava:13b

Write-Host ""
Write-Host "Pulling embedding model (nomic-embed-text)..." -ForegroundColor Yellow
docker exec ollama ollama pull nomic-embed-text

Write-Host ""
$response = Read-Host "Do you have 24GB+ VRAM? Pull smart model? (y/n)"
if ($response -eq 'y') {
    Write-Host "Pulling smart model (qwen2.5:32b)..." -ForegroundColor Yellow
    docker exec ollama ollama pull qwen2.5:32b
}

Write-Host ""
Write-Host "========================================"
Write-Host "  Models Installed:"
Write-Host "========================================"
docker exec ollama ollama list

Write-Host ""
Write-Host "Done! Test with:" -ForegroundColor Green
Write-Host '  Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body ''{"model":"llama3.2:8b","prompt":"Hello","stream":false}'' -ContentType "application/json"'
