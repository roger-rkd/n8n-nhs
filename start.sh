#!/bin/sh

echo "Preparing n8n directory..."
mkdir -p /root/.n8n

echo "Importing workflow..."
n8n import:workflow --input=/app/workflows/chat_workflow.json

echo "Publishing workflow..."
n8n publish:workflow --id=chat_workflow

echo "Starting n8n..."
n8n start &

echo "Waiting for n8n to initialize..."
sleep 10

export N8N_BASE_URL=https://n8n-nhs.onrender.com

echo "Starting FastAPI..."
uvicorn backend.app:app --host 0.0.0.0 --port 7860
