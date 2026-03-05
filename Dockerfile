FROM python:3.11-slim

RUN apt-get update && apt-get install -y curl gnupg

# install Node.js 22
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && apt-get install -y nodejs

# install n8n
RUN npm install -g n8n

WORKDIR /app

COPY . .

RUN pip install fastapi uvicorn pydantic

ENV N8N_PORT=5678
ENV N8N_HOST=0.0.0.0
ENV N8N_PROTOCOL=http
ENV N8N_ENCRYPTION_KEY=nhs-demo-key
ENV N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true

RUN chmod +x start.sh

EXPOSE 7860

CMD ["bash","start.sh"]
