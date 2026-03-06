#!/bin/sh
set -e

export N8N_HOST="${N8N_HOST:-0.0.0.0}"
export N8N_PORT="${N8N_PORT:-${PORT:-5678}}"
export N8N_PROTOCOL="${N8N_PROTOCOL:-https}"
export N8N_ENCRYPTION_KEY="${N8N_ENCRYPTION_KEY:-nhs-demo-key}"
export N8N_USER_MANAGEMENT_DISABLED="${N8N_USER_MANAGEMENT_DISABLED:-true}"

echo "Preparing n8n data directory..."
mkdir -p /home/node/.n8n

echo "Starting n8n..."
exec n8n start
