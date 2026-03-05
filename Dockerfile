FROM n8nio/n8n:latest

USER root

RUN apk add --no-cache python3 py3-pip

WORKDIR /app

COPY . .

RUN pip3 install fastapi uvicorn pydantic

ENV N8N_PORT=5678
ENV N8N_HOST=0.0.0.0
ENV N8N_PROTOCOL=http
ENV N8N_ENCRYPTION_KEY=nhs-demo-key
ENV N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true

EXPOSE 7860

RUN chmod +x start.sh

CMD ["bash", "start.sh"]
