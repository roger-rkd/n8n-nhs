import json
import os
import time
from pathlib import Path
from threading import Lock
from typing import Any, Dict, List
from urllib import error, request

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

app = FastAPI(title="AI Health Assistant Backend")
FRONTEND_DIR = Path(__file__).resolve().parent.parent / "frontend"
INDEX_FILE = FRONTEND_DIR / "index.html"
app.mount("/static", StaticFiles(directory=str(FRONTEND_DIR)), name="static")

# In-memory session storage: {session_id: {"history": [...], "last_seen": timestamp}}
sessions: Dict[str, Dict[str, Any]] = {}
# Per-session rate-limit timestamps: {session_id: [timestamp, ...]}
rate_limits: Dict[str, List[float]] = {}
sessions_lock = Lock()
RATE_LIMIT_MAX_REQUESTS = 10
RATE_LIMIT_WINDOW_SECONDS = 60.0

BLOCKED_PATTERNS = [
    "ignore previous instructions",
    "reveal system prompt",
    "bypass restrictions",
    "override safety",
]


def _format_field(value: Any) -> str:
    if isinstance(value, list):
        return ", ".join(str(v) for v in value)
    if value is None:
        return ""
    return str(value)


def load_nhs_context() -> str:
    conditions_dir = Path(__file__).resolve().parent.parent / "kb" / "conditions"
    if not conditions_dir.exists() or not conditions_dir.is_dir():
        return ""

    condition_blocks: List[str] = []
    for file_path in sorted(conditions_dir.glob("*.json")):
        try:
            data = json.loads(file_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue

        lines = [
            f"Condition: {_format_field(data.get('condition'))}",
            f"Overview: {_format_field(data.get('overview'))}",
            f"Symptoms: {_format_field(data.get('symptoms'))}",
            f"Self Care: {_format_field(data.get('self_care'))}",
            f"When to see GP: {_format_field(data.get('when_to_see_gp'))}",
            f"When to call 111: {_format_field(data.get('when_to_call_111'))}",
            f"When to call 999: {_format_field(data.get('when_to_call_999'))}",
        ]
        condition_blocks.append("\n".join(lines))

    return "\n---\n".join(condition_blocks)


# Loaded once when the server process starts.
NHS_CONTEXT = load_nhs_context()


class ChatRequest(BaseModel):
    session_id: str
    message: str


def contains_blocked_pattern(message: str) -> bool:
    lowered = message.lower()
    return any(pattern in lowered for pattern in BLOCKED_PATTERNS)


def get_n8n_base_url() -> str:
    base_url = os.getenv("N8N_BASE_URL", "https://n8n-nhs.onrender.com").strip()
    return base_url.rstrip("/")


def get_session_ttl_seconds() -> float:
    raw_ttl = os.getenv("SESSION_TTL_MINUTES", "30").strip()
    try:
        ttl_minutes = float(raw_ttl)
    except ValueError as exc:
        raise HTTPException(status_code=500, detail="SESSION_TTL_MINUTES must be a number") from exc

    if ttl_minutes <= 0:
        raise HTTPException(status_code=500, detail="SESSION_TTL_MINUTES must be greater than 0")

    return ttl_minutes * 60


def remove_expired_sessions(now_ts: float, ttl_seconds: float) -> List[str]:
    expired_ids = [
        session_id
        for session_id, session_data in sessions.items()
        if now_ts - float(session_data.get("last_seen", 0)) > ttl_seconds
    ]
    for session_id in expired_ids:
        sessions.pop(session_id, None)
    return expired_ids


def enforce_rate_limit(session_id: str, now_ts: float) -> None:
    recent_timestamps = [
        ts for ts in rate_limits.get(session_id, []) if now_ts - ts <= RATE_LIMIT_WINDOW_SECONDS
    ]
    if len(recent_timestamps) >= RATE_LIMIT_MAX_REQUESTS:
        raise HTTPException(
            status_code=429,
            detail="Too many requests. Please wait before sending more messages.",
        )
    recent_timestamps.append(now_ts)
    rate_limits[session_id] = recent_timestamps


def call_n8n_chat_webhook(payload: dict) -> str:
    url = f"{get_n8n_base_url()}/webhook/chat"
    body = json.dumps(payload).encode("utf-8")

    req = request.Request(
        url=url,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    raw = ""
    max_attempts = 5
    for attempt in range(max_attempts):
        try:
            with request.urlopen(req, timeout=30) as resp:
                raw = resp.read().decode("utf-8")
            break
        except error.HTTPError as exc:
            # Render free instances can return transient errors during cold start.
            if exc.code in (429, 502, 503, 504) and attempt < max_attempts - 1:
                time.sleep(2 ** attempt)
                continue
            raise HTTPException(status_code=502, detail=f"n8n returned HTTP {exc.code}") from exc
        except error.URLError as exc:
            if attempt < max_attempts - 1:
                time.sleep(2 ** attempt)
                continue
            raise HTTPException(status_code=502, detail="Failed to reach n8n") from exc

    try:
        data = json.loads(raw) if raw else {}
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=502, detail="Invalid JSON response from n8n") from exc

    response_text = data.get("response")
    if not isinstance(response_text, str):
        raise HTTPException(status_code=502, detail="n8n response missing 'response' field")

    return response_text


def call_groq_chat_fallback(payload: dict) -> str:
    api_key = os.getenv("GROQ_API_KEY", "").strip()
    if not api_key:
        raise HTTPException(status_code=502, detail="n8n unavailable and GROQ_API_KEY not set")

    url = "https://api.groq.com/openai/v1/chat/completions"
    body = json.dumps(
        {
            "model": "llama-3.3-70b-versatile",
            "messages": [
                {
                    "role": "system",
                    "content": (
                        "You are an NHS-safe virtual health assistant.\n"
                        "Use ONLY the NHS context provided below when giving advice.\n\n"
                        f"NHS Context:\n{payload.get('nhs_context', '')}"
                    ),
                },
                {
                    "role": "user",
                    "content": (
                        f"Conversation history: {json.dumps(payload.get('history', []))}\n\n"
                        f"User message: {payload.get('message', '')}"
                    ),
                },
            ],
        }
    ).encode("utf-8")

    req = request.Request(
        url=url,
        data=body,
        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
        method="POST",
    )

    try:
        with request.urlopen(req, timeout=30) as resp:
            raw = resp.read().decode("utf-8")
    except Exception as exc:
        raise HTTPException(status_code=502, detail="Groq fallback failed") from exc

    try:
        data = json.loads(raw) if raw else {}
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=502, detail="Invalid Groq fallback response") from exc

    text = data.get("choices", [{}])[0].get("message", {}).get("content")
    if not isinstance(text, str) or not text.strip():
        raise HTTPException(status_code=502, detail="Groq fallback missing response text")
    return text


@app.get("/")
def read_index():
    if not INDEX_FILE.exists():
        raise HTTPException(status_code=404, detail="Frontend index not found")
    return FileResponse(INDEX_FILE)


@app.post("/chat")
def chat(req: ChatRequest):
    if contains_blocked_pattern(req.message):
        raise HTTPException(status_code=400, detail="Message contains blocked prompt-injection pattern")

    ttl_seconds = get_session_ttl_seconds()
    now_ts = time.time()

    with sessions_lock:
        expired_session_ids = remove_expired_sessions(now_ts=now_ts, ttl_seconds=ttl_seconds)
        for expired_session_id in expired_session_ids:
            rate_limits.pop(expired_session_id, None)

        enforce_rate_limit(session_id=req.session_id, now_ts=now_ts)

        session = sessions.setdefault(req.session_id, {"history": [], "last_seen": now_ts})
        session_history: List[dict] = session["history"]
        session_history.append({"role": "user", "content": req.message})
        session["last_seen"] = now_ts

        payload = {
            "session_id": req.session_id,
            "message": req.message,
            "history": list(session_history),
            "nhs_context": NHS_CONTEXT,
        }

    try:
        assistant_response = call_n8n_chat_webhook(payload)
    except HTTPException as exc:
        if exc.status_code == 502:
            assistant_response = call_groq_chat_fallback(payload)
        else:
            raise

    with sessions_lock:
        session = sessions.setdefault(req.session_id, {"history": [], "last_seen": time.time()})
        session["history"].append({"role": "assistant", "content": assistant_response})
        session["last_seen"] = time.time()

    return {"response": assistant_response, "session_id": req.session_id}
