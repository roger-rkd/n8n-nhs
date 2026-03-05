#!/bin/bash

echo "Starting n8n..."
n8n &

sleep 8

echo "Starting FastAPI..."
uvicorn backend.app:app --host 0.0.0.0 --port 7860