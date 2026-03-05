FROM node:18-bullseye

WORKDIR /app

ENV N8N_PORT=5678
ENV N8N_HOST=0.0.0.0
ENV N8N_PROTOCOL=http
ENV N8N_ENCRYPTION_KEY=nhs-demo-key

# install python
RUN apt-get update && apt-get install -y python3 python3-pip

# install n8n
RUN npm install -g n8n

# copy project
COPY . .
RUN chmod +x start.sh

# install backend dependencies
RUN pip3 install -r requirements.txt

# expose huggingface port
EXPOSE 7860

# start services
CMD ["bash", "start.sh"]
