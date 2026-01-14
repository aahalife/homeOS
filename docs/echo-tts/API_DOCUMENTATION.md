# Echo-TTS REST API Documentation

**Base URL:** `https://reef-moon.exe.xyz`

## Overview

This API provides voice cloning and text-to-speech capabilities powered by the [Echo-TTS model](https://github.com/jordandare/echo-tts). Voice references can be persisted by ID, allowing reuse without re-uploading audio files.

---

## Authentication

All endpoints require API key authentication. Provide your API key using one of these methods:

### Option 1: Bearer Token (Recommended)
```http
Authorization: Bearer YOUR_API_KEY
```

### Option 2: X-API-Key Header
```http
X-API-Key: YOUR_API_KEY
```

### Option 3: Query Parameter
```
?api_key=YOUR_API_KEY
```

**Example with Bearer token:**
```bash
curl -H "Authorization: Bearer YOUR_API_KEY" https://reef-moon.exe.xyz/voices
```

**Error Response (401 Unauthorized):**
```json
{
  "error": "Invalid or missing API key"
}
```

---

## Default Settings

The API is configured with optimal defaults as recommended:

| Setting | Value | Description |
|---------|-------|-------------|
| Speaker KV | **Enabled** | Forces the model to match the reference speaker |
| Speaker KV Scale | **1.5** | Scale factor for speaker conditioning |
| Diffusion Steps | 40 | Quality/speed tradeoff |
| Preset | Independent (High Speaker CFG) | Sampler configuration |

---

## Endpoints

### Health Check

```http
GET /health
```

Returns service health status.

**Response:**
```json
{
  "status": "healthy",
  "service": "echo-tts-api",
  "timestamp": "2025-01-14T10:00:00Z"
}
```

---

### List All Voices

```http
GET /voices
```

Returns a list of all registered voice IDs with metadata.

**Response:**
```json
{
  "voices": [
    {
      "id": "john",
      "name": "John's Voice",
      "created_at": "2025-01-14T10:00:00Z",
      "description": "Male speaker sample"
    }
  ]
}
```

---

### Get Voice Details

```http
GET /voices/{voice_id}
```

Returns details about a specific registered voice.

**Response:**
```json
{
  "id": "john",
  "name": "John's Voice",
  "created_at": "2025-01-14T10:00:00Z",
  "description": "Male speaker sample",
  "file_size_bytes": 245760
}
```

**Error (404):**
```json
{
  "error": "Voice not found: xyz"
}
```

---

### Register a New Voice

```http
POST /voices
Content-Type: multipart/form-data
```

Registers a new voice from a reference audio file. The voice can then be used for TTS without re-uploading the audio.

**Form Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `audio` | file | Yes | Reference audio file (WAV, MP3, OGG, FLAC, M4A, AAC) |
| `id` | string | No | Custom voice ID (auto-generated if not provided) |
| `name` | string | No | Display name for the voice |
| `description` | string | No | Voice description |

**Example (curl):**
```bash
curl -X POST https://reef-moon.exe.xyz/voices \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -F "audio=@reference.wav" \
  -F "id=john" \
  -F "name=John's Voice" \
  -F "description=Male speaker sample"
```

**Response (201 Created):**
```json
{
  "id": "john",
  "name": "John's Voice",
  "created_at": "2025-01-14T10:00:00Z",
  "message": "Voice registered successfully"
}
```

**Error (409 Conflict):**
```json
{
  "error": "Voice ID already exists: john"
}
```

---

### Delete a Voice

```http
DELETE /voices/{voice_id}
```

Deletes a registered voice and its audio file.

**Response:**
```json
{
  "message": "Voice deleted: john"
}
```

---

### Generate Speech (TTS)

```http
POST /tts
```

Generate speech from text using a registered voice or one-time audio upload.

#### Option A: JSON Body (with registered voice)

```http
Content-Type: application/json
```

**Body:**
```json
{
  "text": "Hello, this is a test of the voice cloning system.",
  "voice_id": "john",
  "num_steps": 40,
  "rng_seed": 0,
  "speaker_kv_enable": true,
  "speaker_kv_scale": 1.5
}
```

#### Option B: Multipart Form (with audio file)

```http
Content-Type: multipart/form-data
```

**Form Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `text` | string | Yes | Text to synthesize |
| `voice_id` | string | No* | ID of a registered voice |
| `audio` | file | No* | One-time reference audio file |
| `num_steps` | int | No | Diffusion steps (default: 40) |
| `rng_seed` | int | No | Random seed for reproducibility (default: 0) |
| `speaker_kv_enable` | bool | No | Enable speaker KV scaling (default: true) |
| `speaker_kv_scale` | float | No | Speaker KV scale factor (default: 1.5) |
| `preset_name` | string | No | Sampler preset name |

*Either `voice_id` OR `audio` must be provided.

**Example (curl with registered voice):**
```bash
curl -X POST https://reef-moon.exe.xyz/tts \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello world!", "voice_id": "john"}' \
  --output output.wav
```

**Example (curl with audio file):**
```bash
curl -X POST https://reef-moon.exe.xyz/tts \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -F "text=Hello world!" \
  -F "audio=@reference.wav" \
  --output output.wav
```

**Response:**

Returns WAV audio file directly (Content-Type: audio/wav).

**Error Response:**
```json
{
  "error": "TTS generation failed: ..."
}
```

---

## Generation Parameters

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `num_steps` | 40 | 1-80 | Number of diffusion steps. Higher = better quality, slower. |
| `rng_seed` | 0 | any int | Random seed for reproducible output. |
| `speaker_kv_enable` | true | true/false | Enable speaker KV attention scaling. Helps match reference voice. |
| `speaker_kv_scale` | 1.5 | 1.0-2.0 | Scale factor for speaker KV. Higher = stronger voice adherence. |
| `preset_name` | "Independent (High Speaker CFG)" | see below | Sampler preset. |

**Available Presets:**
- `Independent (High Speaker CFG)` (recommended)
- `Independent (High Speaker CFG) Flat`
- `Independent (High CFG)`
- `Independent (High CFG) Flat`
- `Independent`
- `Independent Flat`

---

## Text Format

Text prompts follow the [WhisperD](https://huggingface.co/jordand/whisper-d-v1a) transcription format:

- The API automatically prepends `[S1] ` if not present
- **Commas** function as pauses
- **Exclamation points** may increase expressiveness
- Colons, semicolons, and em-dashes are normalized to commas

**Example:**
```
Hello, this is a test. How are you doing today?
```

---

## Reference Audio Guidelines

- **Duration:** 10-30 seconds works well; up to 5 minutes supported
- **Quality:** Clear audio with minimal background noise is best
- **Format:** WAV, MP3, OGG, FLAC, M4A, AAC
- **Tip:** If generated voice doesn't match reference, ensure `speaker_kv_enable=true`

---

## Response Times

- **Typical:** 10-30 seconds per request
- **Factors:** Text length, HuggingFace Space queue, network latency

---

## Error Handling

All errors return JSON with an `error` field:

```json
{
  "error": "Error description here"
}
```

**HTTP Status Codes:**

| Code | Description |
|------|-------------|
| 200 | Success |
| 201 | Created (voice registered) |
| 400 | Bad request (missing required parameters) |
| 404 | Voice not found |
| 401 | Unauthorized (invalid or missing API key) |
| 409 | Conflict (voice ID already exists) |
| 500 | Server error (TTS generation failed) |

---

## Example Workflow

### 1. Register a voice

```bash
curl -X POST https://reef-moon.exe.xyz/voices \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -F "audio=@speaker_sample.wav" \
  -F "id=alice"
```

### 2. Generate speech (using registered voice)

```bash
curl -X POST https://reef-moon.exe.xyz/tts \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"text": "Welcome to our service! How can I help you today?", "voice_id": "alice"}' \
  --output welcome.wav
```

### 3. Generate speech (with new seed for variation)

```bash
curl -X POST https://reef-moon.exe.xyz/tts \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"text": "Thank you for your purchase.", "voice_id": "alice", "rng_seed": 42}' \
  --output thanks.wav
```

### 4. One-time voice (no registration)

```bash
curl -X POST https://reef-moon.exe.xyz/tts \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -F "text=Quick test with a different voice." \
  -F "audio=@temp_reference.mp3" \
  --output test.wav
```

---

## SDK Examples

### Python (requests)

```python
import requests

BASE_URL = "https://reef-moon.exe.xyz"
API_KEY = "YOUR_API_KEY"

headers = {"Authorization": f"Bearer {API_KEY}"}

# Register a voice
with open("reference.wav", "rb") as f:
    response = requests.post(
        f"{BASE_URL}/voices",
        headers=headers,
        files={"audio": f},
        data={"id": "myvoice", "name": "My Voice"}
    )
    print(response.json())

# Generate speech
response = requests.post(
    f"{BASE_URL}/tts",
    headers={**headers, "Content-Type": "application/json"},
    json={
        "text": "Hello from Python!",
        "voice_id": "myvoice"
    }
)

if response.status_code == 200:
    with open("output.wav", "wb") as f:
        f.write(response.content)
else:
    print(f"Error: {response.json()}")
```

### JavaScript (fetch)

```javascript
const BASE_URL = "https://reef-moon.exe.xyz";
const API_KEY = "YOUR_API_KEY";

const authHeaders = {
  "Authorization": `Bearer ${API_KEY}`
};

// Register a voice
async function registerVoice(audioFile, id, name) {
  const formData = new FormData();
  formData.append("audio", audioFile);
  formData.append("id", id);
  formData.append("name", name);

  const response = await fetch(`${BASE_URL}/voices`, {
    method: "POST",
    headers: authHeaders,
    body: formData
  });
  return response.json();
}

// Generate speech
async function generateSpeech(text, voiceId) {
  const response = await fetch(`${BASE_URL}/tts`, {
    method: "POST",
    headers: { 
      ...authHeaders,
      "Content-Type": "application/json" 
    },
    body: JSON.stringify({ text, voice_id: voiceId })
  });
  
  if (response.ok) {
    return response.blob();
  }
  throw new Error(await response.text());
}

// Usage
const audioBlob = await generateSpeech("Hello from JavaScript!", "myvoice");
const audioUrl = URL.createObjectURL(audioBlob);
```

---

## Notes

- This service relies on the [HuggingFace Echo-TTS Space](https://huggingface.co/spaces/jordand/echo-tts-preview) as backend
- Audio outputs are [CC-BY-NC-SA-4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) licensed due to Fish Speech S1-DAC dependency
- Please use responsibly and do not impersonate real people without consent
