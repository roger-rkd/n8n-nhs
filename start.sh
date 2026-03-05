#!/bin/sh

echo "Starting n8n in background..."
n8n &

echo "Waiting for n8n to boot..."
sleep 15

echo "Importing workflow..."
n8n import:workflow --input=/app/workflows/chat_workflow.json

echo "Publishing workflow..."
n8n publish:workflow --id=chat_workflow

echo "Starting FastAPI..."
uvicorn backend.app:app --host 0.0.0.0 --port 7860