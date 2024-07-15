#!/bin/bash

docker rm -f $(docker ps -aq)
docker network prune -f
docker volume prune -f

docker network create traefik-network

docker run -d \
  --name=traefik \
  --restart unless-stopped \
  -p 80:80 \
  -p 443:443 \
  -p 8090:8090 \
  -p 8091:8091 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(pwd)/traefik.toml:/etc/traefik/traefik.toml \
  -v $(pwd)/dynamic.toml:/etc/traefik/dynamic/dynamic.toml \
  -v $(pwd)/certs:/etc/traefik/certs \
  --network=traefik-network \
  --label "traefik.enable=true" \
  --label "traefik.http.routers.traefik.rule=Host(`traefik.local`)" \
  --label "traefik.http.routers.traefik.entrypoints=websecure" \
  --label "traefik.http.routers.traefik.tls=true" \
  --label "traefik.http.routers.traefik.service=api@internal" \
  --label "traefik.http.routers.traefik.tls.certresolver=le" \
  traefik:v2.5


docker run -d \
  --name=mariadb-server \
  --restart unless-stopped \
  -e MYSQL_ROOT_PASSWORD='rootpassword' \
  --network=traefik-network \
  mariadb:10.5

docker run -d \
  --name=zabbix-server-mysql \
  --restart unless-stopped \
  -e DB_SERVER_HOST="mariadb-server" \
  -e MYSQL_DATABASE='zabbix' \
  -e MYSQL_USER='zabbix' \
  -e MYSQL_PASSWORD='zabbix' \
  -e MYSQL_ROOT_PASSWORD='rootpassword' \
  --network=traefik-network \
  -p 10051:10051 \
  zabbix/zabbix-server-mysql:alpine-7.0-latest

docker run -d \
  --name=zabbix-web-nginx-mysql \
  --restart unless-stopped \
  -e ZBX_SERVER_HOST="zabbix-server-mysql" \
  -e DB_SERVER_HOST="mariadb-server" \
  -e MYSQL_DATABASE='zabbix' \
  -e MYSQL_USER='zabbix' \
  -e MYSQL_PASSWORD='zabbix' \
  -e MYSQL_ROOT_PASSWORD='rootpassword' \
  --network=traefik-network \
  -p 8082:8080 \
  --label "traefik.enable=true" \
  --label 'traefik.http.routers.zabbix.rule=Host(`zabbix.local`)' \
  --label 'traefik.http.routers.zabbix.entrypoints=websecure' \
  --label 'traefik.http.routers.zabbix.tls=true' \
  zabbix/zabbix-web-nginx-mysql:alpine-7.0-latest

docker run -d \
  --name=zabbix-java-gateway \
  --restart unless-stopped \
  --network=traefik-network \
  -p 10052:10052 \
  zabbix/zabbix-java-gateway:alpine-7.0-latest

docker run -d \
  --name=glpi \
  --restart unless-stopped \
  -e DB_HOST=mariadb-server \
  -e DB_USER=glpi_user \
  -e DB_PASSWORD=glpi_password \
  -e DB_NAME=glpidb \
  -e MYSQL_ROOT_PASSWORD='rootpassword' \
  --network=traefik-network \
  -p 8081:80 \
  --label "traefik.enable=true" \
  --label 'traefik.http.routers.glpi.rule=Host(`glpi.local`)' \
  --label 'traefik.http.routers.glpi.entrypoints=websecure' \
  --label 'traefik.http.routers.glpi.tls=true' \
  diouxx/glpi

docker run -d \
  --name=portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  --network=traefik-network \
  -p 9002:9000 \
  -p 9443:9443 \
  --label 'traefik.enable=true' \
  --label 'traefik.http.routers.portainer.rule=Host("portainer.local")' \
  --label 'traefik.http.routers.portainer.entrypoints=websecure' \
  --label 'traefik.http.routers.portainer.tls=true' \
  portainer/portainer-ce

docker build -t my-apache2-webserver .

docker run -d \
  --name=apache2-webserver \
  --restart unless-stopped \
  -p 8083:80 \
  --network=traefik-network \
  --label "traefik.enable=true" \
  --label 'traefik.http.routers.apache2.rule=Host(`tools.local`)' \
  --label 'traefik.http.routers.apache2.entrypoints=websecure' \
  --label 'traefik.http.routers.apache2.tls=true' \
  my-apache2-webserver

docker run -d \
  --name=prometheus \
  --restart unless-stopped \
  -p 9090:9090 \
  --network=traefik-network \
  --label "traefik.enable=true" \
  --label 'traefik.http.routers.prometheus.rule=Host(`prometheus.local`)' \
  --label 'traefik.http.routers.prometheus.entrypoints=websecure' \
  --label 'traefik.http.routers.prometheus.tls=true' \
  prom/prometheus

docker run -d \
  --name=grafana \
  --restart unless-stopped \
  -p 3000:3000 \
  --network=traefik-network \
  --label "traefik.enable=true" \
  --label 'traefik.http.routers.grafana.rule=Host(`grafana.local`)' \
  --label 'traefik.http.routers.grafana.entrypoints=websecure' \
  --label 'traefik.http.routers.grafana.tls=true' \
  grafana/grafana
