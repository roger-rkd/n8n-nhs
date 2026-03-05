FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g n8n

WORKDIR /app

COPY . .

RUN pip install fastapi uvicorn pydantic

ENV N8N_PORT=5678
ENV N8N_HOST=0.0.0.0
ENV N8N_PROTOCOL=http
ENV N8N_ENCRYPTION_KEY=nhs-demo-key
ENV N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true

EXPOSE 7860

RUN chmod +x start.sh

CMD ["bash", "start.sh"]
