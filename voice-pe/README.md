# Voice PE Integration

Setup guide for Home Assistant Voice Preview Edition with custom "Alice" wake word.

## Overview

The Voice PE serves as the "ears" of the Alice system:
1. Listens for wake word "Alice"
2. Streams audio to local Whisper (STT)
3. Sends text to OpenClaw gateway
4. Alice responds
5. TTS plays on target speaker

## Hardware Needed

- Home Assistant Voice Preview Edition ($59)
- USB-C power adapter
- Optional: External speaker via 3.5mm

**Purchase:** https://www.amazon.com/dp/B0DV9W3L1S

## Firmware Options

### Option A: Open Voice PE (Recommended)

Custom firmware with openWakeWord support for custom wake words.

**GitHub:** https://github.com/mike-nott/open-voice-pe

**Setup:**
1. Install ESPHome addon in Home Assistant
2. Copy `open-voice-pe.yaml` to ESPHome config
3. Update WiFi credentials in `secrets.yaml`
4. Flash: `esphome upload open-voice-pe.yaml`

### Option B: Stock Firmware + Server-Side Wake Word

Use stock firmware but stream to HA for wake word detection.

Less customization but simpler setup.

## Custom Wake Word: "Alice"

### Training the Model

1. Open: https://colab.research.google.com/drive/1q1oe2zOyZp7UsB3jJiQ1IFn8z5YfjwEb

2. Enter `Alice` in the `target_word` field

3. Click play to generate pronunciation

4. If it sounds off, try:
   - `Aliss`
   - `Ah-liss`
   - `AL-iss`

5. Run all cells (~1 hour training)

6. Download the `.tflite` file

### Installing the Wake Word

1. Access Home Assistant via Samba:
   ```
   \\homeassistant.local\share
   ```

2. Create folder: `openwakeword`

3. Drop `alice.tflite` into that folder

4. In HA, go to Settings → Voice assistants

5. Configure openWakeWord addon to use custom model

## ESPHome Configuration

`open-voice-pe.yaml` (key sections):

```yaml
substitutions:
  name: open-voice-pe
  friendly_name: "Alice Voice"

wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password

# Wake word config
micro_wake_word:
  models:
    - model: /config/openwakeword/alice.tflite
      
# Voice assistant config
voice_assistant:
  microphone: ...
  speaker: ...
  use_wake_word: true
  
  # Send to OpenClaw instead of HA Assist
  on_wake_word_detected:
    - logger.log: "Alice wake word detected!"
    
  on_stt_end:
    - lambda: |-
        // Forward transcribed text to OpenClaw
        // via HTTP API or webhook
```

## Connecting to OpenClaw

### Option 1: Via Home Assistant Automation

```yaml
automation:
  - alias: "Voice to Alice"
    trigger:
      - platform: event
        event_type: assist_pipeline
        event_data:
          type: intent-end
    action:
      - service: rest_command.openclaw_chat
        data:
          message: "{{ trigger.event.data.text }}"
```

### Option 2: Direct HTTP (from ESPHome)

Configure ESPHome to POST directly to OpenClaw:

```yaml
http_request:
  useragent: esphome/voice-pe
  
# In on_stt_end:
- http_request.post:
    url: http://192.168.1.100:18789/v1/chat/completions
    headers:
      Authorization: Bearer YOUR_TOKEN
      Content-Type: application/json
    json:
      model: openclaw
      messages:
        - role: user
          content: !lambda return id(transcribed_text);
```

## TTS Routing

### Play on Voice PE Speaker

Default behavior - response plays on the device.

### Play on Google/Other Speaker

Use Open Voice PE firmware feature to route TTS to any HA media player:

```yaml
select:
  - platform: template
    name: "TTS Target"
    options:
      - "media_player.living_room"
      - "media_player.kitchen"
      - "media_player.bedroom"
```

## Testing

1. Say "Alice" near the Voice PE
2. Wait for activation sound
3. Say a command: "What time is it?"
4. Check HA logs for STT result
5. Check OpenClaw logs for processing
6. Verify TTS response plays

## Troubleshooting

### Wake word not detecting
- Check microphone gain in ESPHome config
- Ensure openWakeWord addon is running
- Verify custom model is loaded

### STT not working
- Check Whisper server is running: `curl http://ai-server:8080/health`
- Verify network connectivity

### No response from Alice
- Check OpenClaw gateway is running
- Verify HTTP API is enabled in config
- Check logs: `openclaw logs`

### TTS not playing
- Verify target media player is available
- Check ElevenLabs API key is valid
- Try local Piper as fallback

## Files

- `open-voice-pe.yaml` - ESPHome firmware config
- `secrets.yaml.example` - Template for credentials
- `alice.tflite` - Trained wake word model (after training)
