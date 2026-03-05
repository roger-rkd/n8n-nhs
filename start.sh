#!/bin/bash

echo "Starting n8n..."

export N8N_PORT=5678
export N8N_HOST=0.0.0.0
export N8N_PROTOCOL=http
export WEBHOOK_URL=http://localhost:5678

n8n start &

sleep 8

echo "Starting FastAPI..."

uvicorn backend.app:app --host 0.0.0.0 --port 7860
