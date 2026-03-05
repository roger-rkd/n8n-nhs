#!/bin/sh

echo "Preparing n8n directory..."
mkdir -p /root/.n8n

echo "Importing workflow..."
n8n import:workflow --input=/app/workflows/chat_workflow.json

echo "Activating workflow..."
n8n update:workflow --id=chat_workflow --active=true

echo "Starting n8n..."
n8n &

echo "Starting FastAPI..."
uvicorn backend.app:app --host 0.0.0.0 --port 7860