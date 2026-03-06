#!/bin/sh
set -e

echo "Preparing n8n data directory..."
mkdir -p /home/node/.n8n

echo "Importing workflow..."
n8n import:workflow --input=/app/workflows/chat_workflow.json

echo "Activating workflow..."
if ! n8n update:workflow --id=chat_workflow --active=true; then
  echo "Activation by id failed, continuing with imported active flag..."
fi

echo "Starting n8n..."
exec n8n start
