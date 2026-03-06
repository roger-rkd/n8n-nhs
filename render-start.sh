#!/bin/sh
set -e

echo "Preparing n8n data directory..."
mkdir -p /home/node/.n8n

echo "Importing workflow..."
n8n import:workflow --input=/app/workflows/chat_workflow.json

echo "Resolving imported workflow id..."
n8n export:workflow --all --output=/tmp/workflows.json
WORKFLOW_ID="$(node -e "const fs=require('fs');const d=JSON.parse(fs.readFileSync('/tmp/workflows.json','utf8'));const list=Array.isArray(d)?d:[d];const w=list.find(x=>x && x.name==='chat_workflow');if(!w||w.id===undefined||w.id===null){process.exit(1)};process.stdout.write(String(w.id));")"
echo "Workflow id: ${WORKFLOW_ID}"

echo "Activating workflow..."
n8n update:workflow --id="${WORKFLOW_ID}" --active=true

echo "Starting n8n..."
exec n8n start
