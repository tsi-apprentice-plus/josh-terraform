#!/bin/bash     

wait_for_apt() {
  while fuser /var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock >/dev/null 2>&1; do
    echo "Waiting for other apt-get processes to finish..."
    sleep 1
  done
}


sudo apt-get update -y
wait_for_apt
sudo apt-get install ca-certificates curl wget gnupg nginx -y
wait_for_apt
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
wait_for_apt
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
wait_for_apt
sudo usermod -aG docker ubuntu
sudo usermod -aG docker root
sudo chmod a+wx /etc/nginx/sites-available
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
cat <<EOL > /etc/nginx/sites-available/$my_name.netbuildertraining.com
server {
  listen 80;
  listen [::]:80;
  server_name $my_name.netbuildertraining.com;
  location / {
    proxy_pass http://$PRIVATE_IP:$frontend_port;
    include proxy_params;
    proxy_set_header Host \$http_host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }
}
EOL
sudo ln -s /etc/nginx/sites-available/$my_name.netbuildertraining.com /etc/nginx/sites-enabled/
cat <<EOL > /etc/nginx/sites-available/api.$my_name.netbuildertraining.com
server {
  listen 80;
  listen [::]:80;
  server_name api.$my_name.netbuildertraining.com;
  location / {
    proxy_pass http://$PRIVATE_IP:$backend_port;
    include proxy_params;
    proxy_set_header Host \$http_host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }
}
EOL
sudo ln -s /etc/nginx/sites-available/api.$my_name.netbuildertraining.com /etc/nginx/sites-enabled/
cat <<EOL > /tmp/docker-compose.yml
services:
  frontend:
    image: ghcr.io/asharubendy/aamirah-frontend:prod
    ports:
      - "$frontend_port:3000"
    container_name: frontend
  backend:
    image: ghcr.io/aamirahp/backend:latest
    ports:
      - "$backend_port:8080"
    container_name: backend
EOL
sudo docker compose --file /tmp/docker-compose.yml up -d
sudo nginx -t
sudo systemctl restart nginx