#!/bin/sh
set -e

echo "Preparing n8n data directory..."
mkdir -p /home/node/.n8n

echo "Importing workflow..."
n8n import:workflow --input=/app/workflows/chat_workflow.json

echo "Resolving workflow id..."
n8n export:workflow --all --output=/tmp/workflows.json
WORKFLOW_ID="$(node -e "const fs=require('fs');const raw=JSON.parse(fs.readFileSync('/tmp/workflows.json','utf8'));const list=Array.isArray(raw)?raw:(Array.isArray(raw.data)?raw.data:[raw]);const wf=list.find((x)=>x && x.name==='chat_workflow');if(!wf||wf.id===undefined||wf.id===null){process.exit(1)}process.stdout.write(String(wf.id));")"
echo "Publishing workflow id ${WORKFLOW_ID}..."
n8n publish:workflow --id="${WORKFLOW_ID}"

echo "Starting n8n..."
exec n8n start
