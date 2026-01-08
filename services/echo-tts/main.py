"""
Echo-TTS Voice Cloning Service
Provides voice cloning and TTS synthesis using 11Labs API
"""
import os
import io
import uuid
import tempfile
from typing import Optional
from datetime import datetime

from fastapi import FastAPI, HTTPException, UploadFile, File, Form, Depends, Header
from fastapi.responses import StreamingResponse, Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import httpx
from jose import jwt, JWTError
import yt_dlp
from pydub import AudioSegment

app = FastAPI(
    title="Echo-TTS Voice Cloning Service",
    description="Voice cloning and TTS synthesis for HomeOS",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration
ELEVEN_LABS_API_KEY = os.environ.get("ELEVEN_LABS_API_KEY", "")
ELEVEN_LABS_BASE_URL = "https://api.elevenlabs.io/v1"
JWT_SECRET = os.environ.get("JWT_SECRET", "dev-jwt-secret-change-in-production")

# In-memory voice profile storage (replace with database in production)
voice_profiles: dict[str, dict] = {}


class VoiceProfile(BaseModel):
    id: str
    workspace_id: str
    name: str
    source: str  # 'recording', 'youtube', 'default'
    eleven_labs_voice_id: Optional[str] = None
    status: str  # 'processing', 'ready', 'failed'
    created_at: str


class CloneRequest(BaseModel):
    workspace_id: str
    name: str
    source: str = "recording"


class SynthesizeRequest(BaseModel):
    text: str
    voice_profile_id: Optional[str] = None
    use_default: bool = False


class YouTubeCloneRequest(BaseModel):
    workspace_id: str
    name: str
    youtube_url: str
    start_time: int = 0  # Start time in seconds
    duration: int = 30  # Duration to extract in seconds


def verify_token(authorization: str = Header(...)):
    """Verify JWT token from Authorization header"""
    try:
        if not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Invalid authorization header")

        token = authorization[7:]
        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        return payload
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")


@app.get("/health")
async def health():
    """Health check endpoint"""
    return {
        "status": "ok",
        "service": "echo-tts",
        "eleven_labs_configured": bool(ELEVEN_LABS_API_KEY),
    }


@app.get("/voices")
async def list_voices(
    workspace_id: str,
    user: dict = Depends(verify_token),
):
    """List all voice profiles for a workspace"""
    workspace_voices = [
        v for v in voice_profiles.values()
        if v["workspace_id"] == workspace_id
    ]
    return {"voices": workspace_voices}


@app.get("/voices/defaults")
async def list_default_voices(user: dict = Depends(verify_token)):
    """List available default voices from 11Labs"""
    if not ELEVEN_LABS_API_KEY:
        raise HTTPException(status_code=503, detail="11Labs not configured")

    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{ELEVEN_LABS_BASE_URL}/voices",
            headers={"xi-api-key": ELEVEN_LABS_API_KEY},
        )

        if response.status_code != 200:
            raise HTTPException(status_code=500, detail="Failed to fetch voices")

        data = response.json()
        return {
            "voices": [
                {
                    "id": v["voice_id"],
                    "name": v["name"],
                    "preview_url": v.get("preview_url"),
                    "category": v.get("category", "default"),
                }
                for v in data.get("voices", [])
            ]
        }


@app.post("/clone")
async def clone_voice(
    audio: UploadFile = File(...),
    workspace_id: str = Form(...),
    name: str = Form(...),
    user: dict = Depends(verify_token),
):
    """
    Clone a voice from an audio recording (5-30 seconds).
    Accepts WAV, MP3, M4A, or WebM audio files.
    """
    if not ELEVEN_LABS_API_KEY:
        raise HTTPException(status_code=503, detail="11Labs not configured")

    # Read audio file
    audio_content = await audio.read()

    # Validate file size (max 10MB)
    if len(audio_content) > 10 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="Audio file too large (max 10MB)")

    profile_id = str(uuid.uuid4())

    # Create voice profile entry
    voice_profiles[profile_id] = {
        "id": profile_id,
        "workspace_id": workspace_id,
        "name": name,
        "source": "recording",
        "eleven_labs_voice_id": None,
        "status": "processing",
        "created_at": datetime.utcnow().isoformat(),
    }

    try:
        # Clone voice using 11Labs API
        async with httpx.AsyncClient(timeout=120.0) as client:
            files = {
                "files": (audio.filename or "recording.wav", audio_content, audio.content_type or "audio/wav"),
            }
            data = {
                "name": f"HomeOS - {name}",
                "description": f"Voice cloned for HomeOS workspace",
            }

            response = await client.post(
                f"{ELEVEN_LABS_BASE_URL}/voices/add",
                headers={"xi-api-key": ELEVEN_LABS_API_KEY},
                files=files,
                data=data,
            )

            if response.status_code != 200:
                voice_profiles[profile_id]["status"] = "failed"
                error_text = response.text
                raise HTTPException(
                    status_code=500,
                    detail=f"Failed to clone voice: {error_text}"
                )

            result = response.json()
            voice_profiles[profile_id]["eleven_labs_voice_id"] = result["voice_id"]
            voice_profiles[profile_id]["status"] = "ready"

            return {
                "success": True,
                "voice_profile": voice_profiles[profile_id],
            }

    except httpx.TimeoutException:
        voice_profiles[profile_id]["status"] = "failed"
        raise HTTPException(status_code=504, detail="Voice cloning timed out")


@app.post("/clone/youtube")
async def clone_from_youtube(
    request: YouTubeCloneRequest,
    user: dict = Depends(verify_token),
):
    """
    Clone a voice from a YouTube video.
    Extracts audio from the specified time range.
    """
    if not ELEVEN_LABS_API_KEY:
        raise HTTPException(status_code=503, detail="11Labs not configured")

    profile_id = str(uuid.uuid4())

    # Create voice profile entry
    voice_profiles[profile_id] = {
        "id": profile_id,
        "workspace_id": request.workspace_id,
        "name": request.name,
        "source": "youtube",
        "youtube_url": request.youtube_url,
        "eleven_labs_voice_id": None,
        "status": "processing",
        "created_at": datetime.utcnow().isoformat(),
    }

    try:
        # Download audio from YouTube
        with tempfile.TemporaryDirectory() as tmpdir:
            output_path = os.path.join(tmpdir, "audio")

            ydl_opts = {
                "format": "bestaudio/best",
                "outtmpl": output_path,
                "postprocessors": [{
                    "key": "FFmpegExtractAudio",
                    "preferredcodec": "wav",
                    "preferredquality": "192",
                }],
                "quiet": True,
                "no_warnings": True,
            }

            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                ydl.download([request.youtube_url])

            # Find the downloaded file
            audio_file = output_path + ".wav"
            if not os.path.exists(audio_file):
                raise HTTPException(status_code=500, detail="Failed to download audio")

            # Extract the specified segment
            audio = AudioSegment.from_wav(audio_file)
            start_ms = request.start_time * 1000
            end_ms = start_ms + (request.duration * 1000)
            segment = audio[start_ms:end_ms]

            # Export to bytes
            buffer = io.BytesIO()
            segment.export(buffer, format="wav")
            audio_content = buffer.getvalue()

        # Clone voice using 11Labs API
        async with httpx.AsyncClient(timeout=120.0) as client:
            files = {
                "files": ("youtube_audio.wav", audio_content, "audio/wav"),
            }
            data = {
                "name": f"HomeOS - {request.name}",
                "description": f"Voice cloned from YouTube for HomeOS",
            }

            response = await client.post(
                f"{ELEVEN_LABS_BASE_URL}/voices/add",
                headers={"xi-api-key": ELEVEN_LABS_API_KEY},
                files=files,
                data=data,
            )

            if response.status_code != 200:
                voice_profiles[profile_id]["status"] = "failed"
                raise HTTPException(
                    status_code=500,
                    detail=f"Failed to clone voice: {response.text}"
                )

            result = response.json()
            voice_profiles[profile_id]["eleven_labs_voice_id"] = result["voice_id"]
            voice_profiles[profile_id]["status"] = "ready"

            return {
                "success": True,
                "voice_profile": voice_profiles[profile_id],
            }

    except yt_dlp.DownloadError as e:
        voice_profiles[profile_id]["status"] = "failed"
        raise HTTPException(status_code=400, detail=f"Failed to download YouTube video: {str(e)}")
    except Exception as e:
        voice_profiles[profile_id]["status"] = "failed"
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/synthesize")
async def synthesize_speech(
    request: SynthesizeRequest,
    user: dict = Depends(verify_token),
):
    """
    Synthesize speech from text using a cloned voice or default voice.
    Returns audio as MP3.
    """
    if not ELEVEN_LABS_API_KEY:
        raise HTTPException(status_code=503, detail="11Labs not configured")

    # Determine which voice to use
    voice_id = None

    if request.use_default or not request.voice_profile_id:
        # Use a default 11Labs voice (Rachel - warm and clear)
        voice_id = "21m00Tcm4TlvDq8ikWAM"
    else:
        # Get the cloned voice
        profile = voice_profiles.get(request.voice_profile_id)
        if not profile:
            raise HTTPException(status_code=404, detail="Voice profile not found")
        if profile["status"] != "ready":
            raise HTTPException(status_code=400, detail="Voice profile not ready")
        voice_id = profile["eleven_labs_voice_id"]

    if not voice_id:
        raise HTTPException(status_code=400, detail="No voice ID available")

    # Synthesize speech
    async with httpx.AsyncClient(timeout=60.0) as client:
        response = await client.post(
            f"{ELEVEN_LABS_BASE_URL}/text-to-speech/{voice_id}",
            headers={
                "xi-api-key": ELEVEN_LABS_API_KEY,
                "Content-Type": "application/json",
            },
            json={
                "text": request.text,
                "model_id": "eleven_monolingual_v1",
                "voice_settings": {
                    "stability": 0.5,
                    "similarity_boost": 0.75,
                },
            },
        )

        if response.status_code != 200:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to synthesize speech: {response.text}"
            )

        return Response(
            content=response.content,
            media_type="audio/mpeg",
            headers={
                "Content-Disposition": "attachment; filename=speech.mp3",
            },
        )


@app.post("/synthesize/stream")
async def synthesize_speech_stream(
    request: SynthesizeRequest,
    user: dict = Depends(verify_token),
):
    """
    Stream synthesized speech from text.
    Returns chunked audio stream for lower latency.
    """
    if not ELEVEN_LABS_API_KEY:
        raise HTTPException(status_code=503, detail="11Labs not configured")

    # Determine which voice to use
    voice_id = None

    if request.use_default or not request.voice_profile_id:
        voice_id = "21m00Tcm4TlvDq8ikWAM"
    else:
        profile = voice_profiles.get(request.voice_profile_id)
        if not profile:
            raise HTTPException(status_code=404, detail="Voice profile not found")
        if profile["status"] != "ready":
            raise HTTPException(status_code=400, detail="Voice profile not ready")
        voice_id = profile["eleven_labs_voice_id"]

    if not voice_id:
        raise HTTPException(status_code=400, detail="No voice ID available")

    async def stream_audio():
        async with httpx.AsyncClient(timeout=60.0) as client:
            async with client.stream(
                "POST",
                f"{ELEVEN_LABS_BASE_URL}/text-to-speech/{voice_id}/stream",
                headers={
                    "xi-api-key": ELEVEN_LABS_API_KEY,
                    "Content-Type": "application/json",
                },
                json={
                    "text": request.text,
                    "model_id": "eleven_monolingual_v1",
                    "voice_settings": {
                        "stability": 0.5,
                        "similarity_boost": 0.75,
                    },
                },
            ) as response:
                async for chunk in response.aiter_bytes():
                    yield chunk

    return StreamingResponse(
        stream_audio(),
        media_type="audio/mpeg",
    )


@app.delete("/voices/{voice_id}")
async def delete_voice(
    voice_id: str,
    user: dict = Depends(verify_token),
):
    """Delete a cloned voice profile"""
    profile = voice_profiles.get(voice_id)
    if not profile:
        raise HTTPException(status_code=404, detail="Voice profile not found")

    # Delete from 11Labs if it was cloned there
    if profile.get("eleven_labs_voice_id") and ELEVEN_LABS_API_KEY:
        try:
            async with httpx.AsyncClient() as client:
                await client.delete(
                    f"{ELEVEN_LABS_BASE_URL}/voices/{profile['eleven_labs_voice_id']}",
                    headers={"xi-api-key": ELEVEN_LABS_API_KEY},
                )
        except Exception:
            pass  # Continue even if 11Labs deletion fails

    del voice_profiles[voice_id]
    return {"success": True}


@app.get("/youtube/search")
async def search_youtube(
    query: str,
    user: dict = Depends(verify_token),
):
    """Search YouTube for videos (for finding celebrity clips)"""
    try:
        ydl_opts = {
            "quiet": True,
            "no_warnings": True,
            "extract_flat": True,
            "default_search": "ytsearch10",
        }

        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            result = ydl.extract_info(f"ytsearch10:{query}", download=False)

        videos = []
        for entry in result.get("entries", []):
            if entry:
                videos.append({
                    "id": entry.get("id"),
                    "title": entry.get("title"),
                    "url": f"https://www.youtube.com/watch?v={entry.get('id')}",
                    "thumbnail": entry.get("thumbnail"),
                    "duration": entry.get("duration"),
                    "channel": entry.get("channel"),
                })

        return {"videos": videos}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
