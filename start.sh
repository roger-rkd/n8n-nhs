#!/bin/bash

echo "Preparing n8n directory..."
mkdir -p /home/node/.n8n

echo "Importing workflow before startup..."
n8n import:workflow --input=/app/workflows/chat_workflow.json

echo "Starting n8n..."
n8n &

sleep 8

echo "Starting FastAPI..."
uvicorn backend.app:app --host 0.0.0.0 --port 7860