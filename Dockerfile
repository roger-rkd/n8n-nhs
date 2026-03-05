FROM node:18-bullseye

WORKDIR /app

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
