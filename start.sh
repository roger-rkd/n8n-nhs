#!/bin/bash

echo "Starting n8n..."
n8n &

sleep 8

echo "Importing workflow..."
n8n import:workflow --input=workflows/chat_workflow.json
n8n update:workflow --id=chat_workflow --active=true

echo "Starting FastAPI..."
uvicorn backend.app:app --host 0.0.0.0 --port 7860