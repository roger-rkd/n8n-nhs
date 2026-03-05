FROM node:18-bullseye

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends python3 python3-pip bash && rm -rf /var/lib/apt/lists/*
RUN npm install -g n8n

COPY requirements.txt ./requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt

COPY . .

ENV N8N_PORT=5678
ENV N8N_HOST=0.0.0.0
ENV N8N_PROTOCOL=http
ENV N8N_ENCRYPTION_KEY=nhs-demo-key

EXPOSE 7860

RUN chmod +x start.sh

CMD ["bash", "start.sh"]
