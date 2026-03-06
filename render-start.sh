#!/bin/sh
set -e

echo "Preparing n8n data directory..."
mkdir -p /home/node/.n8n

echo "Importing workflow..."
n8n import:workflow --input=/app/workflows/chat_workflow.json

echo "Activating all workflows..."
n8n update:workflow --all --active=true

echo "Starting n8n..."
exec n8n start
