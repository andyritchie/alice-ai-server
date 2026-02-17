# Model Recommendations

Guide for choosing the right model for each task.

## VRAM Requirements

| Model | Size | VRAM (Q4) | VRAM (FP16) | Speed |
|-------|------|-----------|-------------|-------|
| Llama 3.2 8B | 8B | ~5GB | ~16GB | Fast |
| Qwen 2.5 7B | 7B | ~5GB | ~14GB | Fast |
| Qwen 2.5 32B | 32B | ~20GB | ~64GB | Medium |
| Llama 3.3 70B | 70B | ~40GB | ~140GB | Slow |
| DeepSeek R1 32B | 32B | ~20GB | ~64GB | Medium |
| LLaVA 13B | 13B | ~10GB | ~26GB | Medium |

## Recommended Setup by GPU

### RTX 4090 / 3090 (24GB VRAM)
```bash
# Fast model (always loaded)
ollama pull llama3.2:8b

# Smart model (swap in when needed)
ollama pull qwen2.5:32b

# Vision
ollama pull llava:13b

# Coding
ollama pull qwen2.5-coder:7b
```

### RTX 4080 / 3080 (16GB VRAM)
```bash
# Fast model
ollama pull llama3.2:8b

# Medium smart model
ollama pull qwen2.5:14b

# Vision (smaller)
ollama pull llava:7b
```

### RTX 4070 / 3070 (12GB VRAM)
```bash
# Fast model
ollama pull llama3.2:8b

# Smaller vision
ollama pull llava:7b

# Use cloud for complex tasks
```

### RTX 4060 / 3060 (8GB VRAM)
```bash
# Small fast model only
ollama pull llama3.2:3b
ollama pull qwen2.5:3b

# Recommend cloud fallback for most tasks
```

## Model Selection by Task

### Home Control
**Model:** `llama3.2:8b` (local, fast)
- "Turn on the lights"
- "Set temperature to 72"
- "Lock the front door"

Simple commands, needs speed over smarts.

### Quick Questions
**Model:** `llama3.2:8b` or `qwen2.5:7b` (local, fast)
- "What time is it?"
- "What's the weather?"
- "Set a timer for 5 minutes"

### Conversations
**Model:** `qwen2.5:32b` (local) or Claude (cloud)
- Longer discussions
- Context-heavy queries
- Personal assistant tasks

### Coding
**Model:** `qwen2.5-coder:7b` (local) or Claude (cloud)
- Code generation
- Debugging
- Technical explanations

### Image Analysis
**Model:** `llava:13b` (local)
- "What's on the security camera?"
- "Describe this image"
- Object detection

### Complex Reasoning
**Model:** Claude Sonnet/Opus (cloud)
- Multi-step problems
- Research tasks
- Document analysis

## Routing Strategy

```
User command
    ↓
Classify intent (tiny local model or rules)
    ↓
├─ home_control → llama3.2:8b (instant)
├─ quick_question → llama3.2:8b (instant)
├─ image_query → llava:13b (fast)
├─ coding → qwen2.5-coder:7b (fast)
├─ conversation → qwen2.5:32b (medium)
└─ complex → claude-sonnet (smart)
```

## Model Loading

Ollama keeps the last used model in VRAM. To optimize:

```bash
# Pre-load the fast model
curl http://localhost:11434/api/generate -d '{"model":"llama3.2:8b","prompt":"","keep_alive":"24h"}'
```

Set keep_alive to keep model loaded between requests.

## Benchmarks (RTX 4090)

| Model | Tokens/sec | First token |
|-------|-----------|-------------|
| Llama 3.2 8B Q4 | ~120 t/s | ~200ms |
| Qwen 2.5 32B Q4 | ~40 t/s | ~500ms |
| LLaVA 13B | ~60 t/s | ~800ms |
| Claude Sonnet | ~80 t/s | ~1000ms |

Local models beat cloud on latency for first token.

## Cost Comparison

| Task | Cloud (Claude) | Local |
|------|---------------|-------|
| 1000 simple queries | ~$2 | $0 |
| 1000 complex queries | ~$15 | $0 |
| Image analysis (1000) | ~$5 | $0 |
| Monthly typical use | ~$50 | $0 |

Electricity cost for AI server: ~$10-20/mo
