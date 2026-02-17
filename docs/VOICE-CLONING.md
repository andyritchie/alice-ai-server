# Voice Cloning

Create a local clone of Alice's voice — same voice as ElevenLabs, but faster and free.

## Why Clone Locally?

| | ElevenLabs (Cloud) | Local Clone (XTTS) |
|---|-------------------|-------------------|
| Latency | 1-2 seconds | 0.3-0.5 seconds |
| Cost | $22/month | Free |
| Quality | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Works offline | ❌ | ✅ |

**The play:** Generate reference audio from ElevenLabs, use it to clone locally with XTTS.
Same voice, 4x faster, zero ongoing cost.

## Quick Start: Clone Your ElevenLabs Voice

### Step 1: Generate Reference Audio

Run the script to generate voice samples from ElevenLabs:

```powershell
cd C:\AI-Server
node scripts/generate-voice-samples.js
```

This creates ~20 audio samples using your ElevenLabs voice.

### Step 2: Combine into Reference File

```powershell
cd voice-samples/individual

# Create file list
(for %i in (*.mp3) do @echo file '%i') > list.txt

# Combine all samples
ffmpeg -f concat -safe 0 -i list.txt -c copy ../combined.mp3

# Convert to WAV (required format for XTTS)
ffmpeg -i ../combined.mp3 -ar 22050 ../alice_reference.wav
```

### Step 3: Use with XTTS

Now `alice_reference.wav` can be used as the voice reference for XTTS.

```bash
# Test it
curl -X POST "http://localhost:8020/tts_to_audio/" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello, this is Alice speaking locally!", "speaker_wav": "/app/voices/alice_reference.wav", "language": "en"}' \
  --output test.wav
```

**Result:** Same voice, running locally, ~0.3-0.5s instead of 1-2s! 🔥

---

## Options

### Option 1: XTTS v2 (Coqui) - Recommended

High-quality voice cloning with just 6 seconds of audio.

#### Docker Setup

Add to `docker-compose.yml`:

```yaml
xtts:
  image: ghcr.io/coqui-ai/xtts-streaming-server:latest
  container_name: xtts
  restart: unless-stopped
  ports:
    - "8020:80"
  volumes:
    - xtts_data:/app/tts_models
    - ./voices:/app/voices
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: all
            capabilities: [gpu]
  environment:
    - COQUI_TOS_AGREED=1
```

#### Create Voice Clone

1. Get a clean audio sample (6-30 seconds):
   - No background noise
   - Clear speech
   - WAV format, 22050Hz

2. Save to `~/ai-server/voices/alice.wav`

3. Use the API:

```bash
curl -X POST "http://ai-server:8020/tts_to_audio/" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Hello, I am Alice, your personal AI assistant.",
    "speaker_wav": "/app/voices/alice.wav",
    "language": "en"
  }' \
  --output response.wav
```

#### API Endpoints

```
POST /tts_to_audio/
{
  "text": "Text to speak",
  "speaker_wav": "/app/voices/alice.wav",
  "language": "en"
}
Response: audio/wav

POST /tts_stream/
Same params, returns streaming audio
```

### Option 2: OpenVoice

Instant voice cloning with style control.

#### Setup

```yaml
openvoice:
  image: myshell-ai/openvoice:latest
  container_name: openvoice
  restart: unless-stopped
  ports:
    - "8021:8000"
  volumes:
    - openvoice_data:/app/checkpoints
    - ./voices:/app/voices
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: all
            capabilities: [gpu]
```

### Option 3: Piper Custom Voice

Train a custom Piper voice (more work but faster inference).

#### Training Requirements

- 1-2 hours of clean audio
- Transcriptions
- GPU for training
- piper-training toolkit

#### Process

1. Prepare dataset:
```bash
mkdir -p ~/voice-training/alice
# Add WAV files + transcripts
```

2. Train model:
```bash
python -m piper_train \
  --dataset-dir ~/voice-training/alice \
  --output-dir ~/voice-training/output \
  --sample-rate 22050
```

3. Export to ONNX:
```bash
python -m piper_train.export_onnx \
  ~/voice-training/output/model.ckpt \
  ~/ai-server/piper_data/alice.onnx
```

## Getting a Voice Sample

### From ElevenLabs (Recommended)

Use the included script to generate samples automatically:

```powershell
node scripts/generate-voice-samples.js
```

This generates ~20 varied sentences covering different tones, lengths, and emotions — perfect for voice cloning.

**What the script does:**
1. Sends sentences to ElevenLabs API
2. Downloads MP3 for each
3. Saves to `voice-samples/individual/`

**Then combine them:**
```powershell
# Install ffmpeg if needed: winget install ffmpeg
cd voice-samples/individual
(for %i in (*.mp3) do @echo file '%i') > list.txt
ffmpeg -f concat -safe 0 -i list.txt -ar 22050 ../alice_reference.wav
```

### Recording Fresh

Best quality = recording specifically for cloning:

1. Use a good microphone
2. Quiet room, no echo
3. Read a variety of sentences
4. Keep consistent tone/energy
5. Record 2-5 minutes total
6. Export as WAV, 22050Hz

### Sample Script to Read

```
Hello, I'm Alice. I'll be your AI assistant today.
The weather looks quite nice outside.
Let me check that information for you.
I've completed the task you requested.
Is there anything else I can help you with?
That's an interesting question. Let me think about it.
I'm sorry, but I don't have access to that information.
Great news! Everything is working as expected.
Would you like me to set a reminder for that?
I'll send that message right away.
```

## Integration with OpenClaw

### XTTS Integration

Create `scripts/xtts-tts.js`:

```javascript
const fetch = require('node-fetch');
const fs = require('fs');

async function speak(text) {
    const response = await fetch('http://ai-server:8020/tts_to_audio/', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            text: text,
            speaker_wav: '/app/voices/alice.wav',
            language: 'en'
        })
    });
    
    const buffer = await response.buffer();
    const outputPath = `/tmp/tts_${Date.now()}.wav`;
    fs.writeFileSync(outputPath, buffer);
    return outputPath;
}

module.exports = { speak };
```

### OpenClaw Config

```json
{
  "tts": {
    "provider": "custom",
    "custom": {
      "endpoint": "http://ai-server:8020/tts_to_audio/",
      "method": "POST",
      "bodyTemplate": {
        "text": "{{text}}",
        "speaker_wav": "/app/voices/alice.wav",
        "language": "en"
      }
    }
  }
}
```

## Quality Comparison

| Service | Quality | Speed | Cost |
|---------|---------|-------|------|
| ElevenLabs | ⭐⭐⭐⭐⭐ | Medium | $22/mo |
| XTTS v2 | ⭐⭐⭐⭐ | Medium | Free |
| OpenVoice | ⭐⭐⭐⭐ | Fast | Free |
| Piper Custom | ⭐⭐⭐ | Very Fast | Free |

## Recommendation

1. **Start with XTTS v2** - Best quality-to-effort ratio
2. **Keep ElevenLabs as backup** - For when you need premium quality
3. **Use Piper for speed** - Simple announcements, timers, etc.

### Hybrid Approach

```javascript
async function speak(text, priority = 'normal') {
    if (priority === 'high') {
        // Use ElevenLabs for important messages
        return elevenlabs.speak(text);
    } else if (text.length < 50) {
        // Use fast Piper for short messages
        return piper.speak(text);
    } else {
        // Use XTTS for everything else
        return xtts.speak(text);
    }
}
```

## Troubleshooting

### XTTS Out of Memory

- Reduce max text length
- Use streaming mode
- Reduce batch size

### Voice Doesn't Sound Right

- Use cleaner reference audio
- Try different audio samples
- Ensure sample is 22050Hz

### Slow Generation

- Enable GPU acceleration
- Use streaming for long text
- Consider Piper for speed-critical uses
