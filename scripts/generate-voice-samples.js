/**
 * Generate ElevenLabs voice samples for local cloning
 * 
 * This creates reference audio files that can be used with XTTS/OpenVoice
 * to clone Alice's voice locally.
 * 
 * Usage: node generate-voice-samples.js
 * Output: ./voice-samples/alice_reference.wav (combined)
 *         ./voice-samples/individual/*.wav (separate files)
 */

const https = require('https');
const fs = require('fs');
const path = require('path');

// ============================================
// CONFIGURATION - Update these!
// ============================================
const ELEVENLABS_API_KEY = process.env.ELEVENLABS_API_KEY || 'sk_e2386ada954dd1e037d02e943a2fb2362af5833bd510f004';
const VOICE_ID = process.env.ELEVENLABS_VOICE_ID || '21m00Tcm4TlvDq8ikWAM'; // Rachel voice
const OUTPUT_DIR = './voice-samples';

// Varied sentences for good voice cloning
// Include different emotions, lengths, and sounds
const SENTENCES = [
    // Greetings & basics
    "Hello! I'm Alice, your personal assistant.",
    "Good morning! How can I help you today?",
    "Hey there! What would you like me to do?",
    
    // Informational responses
    "The current temperature is 72 degrees and sunny.",
    "Your next meeting is at 3 PM with the marketing team.",
    "You have five unread emails in your inbox.",
    "The time is currently 10:30 AM.",
    
    // Confirmations
    "Done! I've turned on the living room lights.",
    "Got it. I'll remind you about that later.",
    "Sure thing! Playing your favorite playlist now.",
    "Okay, I've added milk to your shopping list.",
    "All set! Your alarm is scheduled for 7 AM.",
    
    // Questions
    "Would you like me to tell you more about that?",
    "Should I set a reminder for this?",
    "Do you want me to play some music?",
    
    // Longer responses (good for capturing natural rhythm)
    "I've checked the weather forecast for the week. It looks like rain on Tuesday and Wednesday, but the rest of the week should be clear.",
    "Based on your calendar, you have a busy day tomorrow with three meetings scheduled. The first one starts at 9 AM.",
    
    // Different tones
    "I'm sorry, I didn't quite catch that. Could you say it again?",
    "Great news! The package you ordered has been delivered.",
    "Hmm, let me think about that for a moment.",
    "Absolutely! I'd be happy to help with that.",
];

// ============================================
// MAIN SCRIPT
// ============================================

async function generateAudio(text, outputPath) {
    return new Promise((resolve, reject) => {
        const data = JSON.stringify({
            text: text,
            model_id: 'eleven_monolingual_v1',
            voice_settings: {
                stability: 0.5,
                similarity_boost: 0.75
            }
        });

        const options = {
            hostname: 'api.elevenlabs.io',
            path: `/v1/text-to-speech/${VOICE_ID}`,
            method: 'POST',
            headers: {
                'xi-api-key': ELEVENLABS_API_KEY,
                'Content-Type': 'application/json',
                'Accept': 'audio/mpeg'
            }
        };

        const req = https.request(options, (res) => {
            if (res.statusCode !== 200) {
                let body = '';
                res.on('data', c => body += c);
                res.on('end', () => reject(new Error(`API error ${res.statusCode}: ${body}`)));
                return;
            }

            const file = fs.createWriteStream(outputPath);
            res.pipe(file);
            file.on('finish', () => {
                file.close();
                resolve(outputPath);
            });
        });

        req.on('error', reject);
        req.write(data);
        req.end();
    });
}

async function main() {
    console.log('=========================================');
    console.log('  ElevenLabs Voice Sample Generator');
    console.log('=========================================\n');

    // Create output directories
    const individualDir = path.join(OUTPUT_DIR, 'individual');
    fs.mkdirSync(individualDir, { recursive: true });

    console.log(`Generating ${SENTENCES.length} audio samples...\n`);

    const files = [];
    
    for (let i = 0; i < SENTENCES.length; i++) {
        const sentence = SENTENCES[i];
        const filename = `sample_${String(i + 1).padStart(2, '0')}.mp3`;
        const filepath = path.join(individualDir, filename);
        
        process.stdout.write(`[${i + 1}/${SENTENCES.length}] "${sentence.substring(0, 40)}..." `);
        
        try {
            await generateAudio(sentence, filepath);
            files.push(filepath);
            console.log('✓');
            
            // Rate limiting - ElevenLabs has limits
            await new Promise(r => setTimeout(r, 500));
        } catch (err) {
            console.log('✗ ' + err.message);
        }
    }

    console.log(`\n=========================================`);
    console.log(`Generated ${files.length} samples in ${individualDir}`);
    console.log(`=========================================\n`);

    console.log('Next steps:');
    console.log('1. Combine the MP3s into one file (or use individually)');
    console.log('2. Convert to WAV: ffmpeg -i combined.mp3 -ar 22050 alice_reference.wav');
    console.log('3. Use with XTTS for local voice cloning');
    console.log('\nTo combine with ffmpeg:');
    console.log(`   cd ${individualDir}`);
    console.log('   (for %i in (*.mp3) do @echo file \'%i\') > list.txt');
    console.log('   ffmpeg -f concat -safe 0 -i list.txt -c copy ../combined.mp3');
    console.log('   ffmpeg -i ../combined.mp3 -ar 22050 ../alice_reference.wav');
}

main().catch(console.error);
