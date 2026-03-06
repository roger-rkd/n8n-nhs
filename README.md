---
title: N8n Nhs
emoji: 🌍
colorFrom: indigo
colorTo: red
sdk: docker
pinned: false
---

# NHS AI Health Assistant

## Deployment Architecture

This repository now uses a clear split deployment model:

1. Render (n8n only)
- Hosts n8n and the chat webhook workflow.
- Uses `Dockerfile.render` and `render-start.sh`.
- Render blueprint: `render.yaml`.

2. Hugging Face Spaces (FastAPI + Frontend)
- Hosts the web UI and backend API.
- Uses root `Dockerfile`.
- Frontend calls FastAPI `/chat`.
- FastAPI forwards to n8n at `N8N_BASE_URL/webhook/chat`.

## Request Flow

Frontend UI
↓
POST /chat (FastAPI)
↓
POST https://n8n-nhs.onrender.com/webhook/chat
↓
n8n workflow (security + emergency + Groq)
↓
FastAPI response
↓
Frontend

## Key Files

- `backend/app.py`: FastAPI API and n8n forwarding.
- `frontend/`: chat UI.
- `workflows/chat_workflow.json`: n8n workflow.
- `Dockerfile`: Hugging Face app image (FastAPI + frontend).
- `Dockerfile.render`: Render n8n image.
- `render-start.sh`: imports/publishes workflow and starts n8n.
- `render.yaml`: Render service configuration.

## Environment Variables

FastAPI side:
- `N8N_BASE_URL=https://n8n-nhs.onrender.com`
- `SESSION_TTL_MINUTES=30` (optional override)

Render n8n side:
- `N8N_HOST=n8n-nhs.onrender.com`
- `N8N_PORT=5678`
- `N8N_PROTOCOL=https`
- `WEBHOOK_URL=https://n8n-nhs.onrender.com/`
- `N8N_EDITOR_BASE_URL=https://n8n-nhs.onrender.com/`
- `N8N_ENCRYPTION_KEY=<set in Render secret env var>`