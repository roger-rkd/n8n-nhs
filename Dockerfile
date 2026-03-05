FROM n8nio/n8n:latest

USER root

RUN apt-get update && apt-get install -y python3 python3-pip

WORKDIR /app

COPY . .

RUN pip3 install -r requirements.txt

ENV N8N_PORT=5678
ENV N8N_HOST=0.0.0.0
ENV N8N_PROTOCOL=http
ENV N8N_ENCRYPTION_KEY=nhs-demo-key

EXPOSE 7860

RUN chmod +x start.sh

CMD ["bash", "start.sh"]
