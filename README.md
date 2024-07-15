# TraefikSysAdmToolBox

## Description

**TraefikSysAdmToolBox** is a comprehensive suite of tools designed to streamline local development and service management using Docker and Traefik. This project provides a robust environment for managing various services with ease, ensuring that each service is properly configured and accessible via HTTPS.

The primary goal of TraefikSysAdmToolBox is to simplify the setup and configuration of development tools, databases, and web services in a local environment. By leveraging Docker Compose, this project ensures that all services are containerized and isolated, providing a consistent and reproducible environment for developers.

Key features include:

- **Easy Installation**: A streamlined installation process using Docker Compose, allowing for quick setup and deployment of services.
- **Centralized Configuration**: Configuration files and environment variables managed in a single location, simplifying adjustments and updates.
- **Secure Access**: Automated SSL certificate generation and management using Traefik, ensuring that all services are accessible via secure HTTPS connections.
- **Modular Architecture**: Support for various tools and services, allowing for easy addition or removal of components as needed.

TraefikSysAdmToolBox is ideal for sytem admins who need a reliable, configurable, and secure local environment for developing and testing web applications and services.

## Table of Contents
1. [Installation](#installation)
   - [Prerequisites](#prerequisites)
   - [Clone the Repository](#clone-the-repository)
   - [Initial Setup](#initial-setup)
     - [Configuration Files](#configuration-files)
       - [init.sql](#init.sql)
       - [traefik.toml and dynamic.toml files](#traefik.toml-and-dynamic.toml-files)
   - [Network Setup](#network-setup)
   - [Generating SSL Certificates](#generating-ssl-certificates)
   - [Installation Script](#installation-script)
   - [Docker Compose](#docker-compose)
   - [Docker Commands](#docker-commands)
     - [Run the Traefik container](#run-the-traefik-container)
     - [Run the MariaDB container](#run-the-mariadb-container)
     - [Run the Zabbix server container](#run-the-zabbix-server-container)
     - [Run the Zabbix web frontend container](#run-the-zabbix-web-frontend-container)
     - [Run the Zabbix Java gateway container](#run-the-zabbix-java-gateway-container)
     - [Run the GLPI container](#run-the-glpi-container)
     - [Run the Portainer container](#run-the-portainer-container)
     - [Build the my-apache2-webserver image](#build-the-my-apache2-webserver-image)
     - [Run the apache2-webserver container](#run-the-apache2-webserver-container)
     - [Run the Prometheus container](#run-the-prometheus-container)
     - [Run the Grafana container](#run-the-grafana-container)
2. [Configuration](#configuration) 
   - [Configuring the hosts file](#configuring-the-hosts-file)
   - [GLPI Configuration](#glpi-configuration)
   - [Portainer Configuration](#portainer-configuration)
   - [Zabbix Configuration](#zabbix-configuration)
   - [Grafana Configuration](#grafana-configuration)
   - [Socks Proxy Configuration](#socks-proxy-configuration) 
3. [Usage](#usage)
4. [Features](#features)
5. [Contributing](#contributing)
6. [License](#license)
7. [Contact](#contact)

## Installation

### Prerequisites
Make sure you have the following installed:

- Docker

- Docker Compose (optional)

### Clone the Repository

```bash
git clone https://github.com/badtux66/TraefikSysAdmToolBox.git
cd TraefikSysAdmToolBox
```


### Initial Setup

#### Configuration Files

##### init.sql
- First, create an init.sql file for database initialization.
- For making Zabbix and GLPI be able to use the same database 
  you need this initilization script. 

```sql
CREATE DATABASE IF NOT EXISTS zabbix CHARACTER SET utf8 COLLATE utf8_bin;
CREATE DATABASE IF NOT EXISTS glpi CHARACTER SET utf8 COLLATE utf8_bin;

CREATE USER 'zabbix'@'%' IDENTIFIED BY 'zabbix_pwd';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'%';

CREATE USER 'glpi_user'@'%' IDENTIFIED BY 'glpi_password';
GRANT ALL PRIVILEGES ON glpi.* TO 'glpi_user'@'%';

FLUSH PRIVILEGES;
```

##### traefik.toml and dynamic.toml files
- Second, create traefik.toml and dynamic.toml files for Traefik configuration.
- In order to properly route the domains you need a seperate dynamic.toml file.



### Network Setup

First, create a Docker network that will be used to connect all the containers:

```bash
docker network create traefik-network
```

### Generating SSL Certificates

- To make services use HTTPS you need ssl/tls certifiacates.
- I made script to generata .key and .crt files for each service
  from rootCA.


```bash
chmod +x generate_certs.sh
sudo ./generate_certs.sh
```



### Installation Script

```bash
chmod +x commands.sh
sudo ./commands.sh
```
### Docker Compose
```bash
docker-compose up -d
```
### Docker Commands

#### Run the Traefik container

```bash
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
```
- `docker run -d`: Runs the container in detached mode.
- `--name=traefik`: Names the container traefik.
- `--restart unless-stopped`: Restarts the container unless it is explicitly stopped.
- `p 80:80`, `-p 443:443`, `-p 8090:8090`, `-p 8091:8091`: Maps host ports to container ports.
- `-v /var/run/docker.sock:/var/run/docker.sock`: Mounts Docker socket to allow Traefik to interact with Docker.
- `-v $(pwd)/traefik.toml:/etc/traefik/traefik.toml`: Mounts the local traefik.toml configuration file.
- `-v $(pwd)/dynamic.toml:/etc/traefik/dynamic/dynamic.toml`: Mounts the local dynamic.toml configuration file.
- `-v $(pwd)/certs:/etc/traefik/certs`: Mounts the local certs directory.
- `--network=traefik-network`:  Connects the container to the traefik-network.
- `--label "traefik.enable=true"`: This label tells Traefik to consider this container for routing. Without this, Traefik will ignore the container.
- `--label "traefik.http.routers.traefik.rule=Host(`traefik.local`)"`: This label defines a routing rule for Traefik. Here, it specifies that requests with the host traefik.local should be routed to this container. The Host function is a matcher for HTTP requests based on the Host header.
- `--label "traefik.http.routers.traefik.entrypoints=websecure"`: This label specifies which entrypoints the router should listen to. websecure is typically defined in the Traefik configuration and usually corresponds to HTTPS entrypoints
- `--label "traefik.http.routers.traefik.tls=true"`: This label enables TLS for the specified router, meaning the traffic will be encrypted using HTTPS.
- `--label "traefik.http.routers.traefik.service=api@internal"`: This label specifies the service to use for this route. Here, api@internal refers to the internal API service provided by Traefik.
- `--label "traefik.http.routers.traefik.tls.certresolver=le"`: This label specifies the certificate resolver to use for generating or fetching TLS certificates. le typically stands for Let's Encrypt, which is commonly used with Traefik for automatic SSL certificate management.
- `traefik:v2.5`: Specifies the Traefik image version.
#### Run the MariaDB container
```bash
docker run -d \
  --name=mariadb-server \
  --restart unless-stopped \
  -e MYSQL_ROOT_PASSWORD='rootpassword' \
  --network=traefik-network \
  mariadb:10.5
```
- `-e MYSQL_ROOT_PASSWORD='rootpassword'`: Sets the root password for MariaDB.
- `mariadb:10.5`: Specifies the MariaDB image version.

#### Run the Zabbix server container
```bash
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
```
- `e DB_SERVER_HOST="mariadb-server`: Sets the MariaDB server host.
- `-e MYSQL_DATABASE='zabbix'`: Creates a database named zabbix.
- `-e MYSQL_USER='zabbix', -e MYSQL_PASSWORD='zabbix'`: Sets the database user and password.
- `-p 10051:10051`: Maps port 10051.
- `zabbix/zabbix-server-mysql:alpine-7.0-latest`: Specifies the Zabbix server image version.

#### Run the Zabbix web frontend container
```bash
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
```
- `-e ZBX_SERVER_HOST="zabbix-server-mysql`: Sets the Zabbix server host.
- ``
- `--label ...`: Sets various labels to configure Traefik routing and services which explained detailed in Run the Traefik container section.

#### Run the Zabbix Java gateway container
```bash
docker run -d \
  --name=zabbix-java-gateway \
  --restart unless-stopped \
  --network=traefik-network \
  -p 10052:10052 \
  zabbix/zabbix-java-gateway:alpine-7.0-latest
```
- `-p 10052:10052`: Maps port 10052.
- Runs the Zabbix Java gateway container.
#### Run the GLPI container
```bash
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
```
- `-e DB_HOST=mariadb-server, -e DB_USER=glpi_user, -e DB_PASSWORD=glpi_password, -e DB_NAME=glpidb`: Sets database credentials and host.
- `-p 8081:80`: Maps port 80 to 8081.
- Labels configure Traefik routing for GLPI.
#### Run the Portainer container
```bash
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
```
- `-v /var/run/docker.sock:/var/run/docker.sock`: Mounts Docker socket for managing Docker.
- `-v portainer_data:/data`: Mounts a volume for Portainer data.
- `-p 9002:9000, -p 9443:9443`: Maps ports 9000 and 9443.
- Labels configure Traefik routing for Portainer

#### Build the my-apache2-webserver image 
```bash
docker build -t my-apache2-webserver .
```
- Builds the image my-apache2-webserver

#### Run the apache2-webserver container
```bash
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
```
- `--name=apache2-webserver`: Names the container apacher2-webserver.
- Labels configure Traefik routing for apache2-webserver
- `-p 8083:80`: Maps port 80 to 8083.

#### Run the Prometheus container
```bash
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
```

#### Run the Grafana container
```bash
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
```

## Configuration

### Configuring the hosts file
- You should configure the `/etc/hosts` file of the machine that you are running the containers
such that:
```bash
127.0.0.1 localhost
127.0.0.1 zabbix.local
127.0.0.1 glpi.local
127.0.0.1 traefik.local
127.0.0.1 portainer.local
127.0.0.1 tools.local
127.0.0.1 prometheus.local
127.0.0.1 grafana.local
```

### GLPI Configuration
- Go to https:// portainer.local
- Click Advanced then click on accept the risk and continue
- select language
- accept the licence agreement (Click Continue)
- Select Install
- Click on Continue

Credentials are:
SQL Server (MariaDB or MySQL): mariadb-server
SQL User: glpi_user
SQL Password: glpi_passwords
IF the credentials for glpi don't work just use root credentials:
SQL Server (MariaDB or MySQL): mariadb-server
SQL User: root
SQL Password: rootpassword

- Choose databse glpi if it already exist, if it doesn't create one named glpi
- Click on Continue 
- Click on Continue 
- Click on Continue 
- Click on Use GLPI

Credentials are:
username: glpi
password: glpi

- You are ready to go!


### Portainer Configuration
- Go to https:// portainer.local
- Click Advanced then click on accept the risk and continue
- Set up the username and password for Portainer
- You are ready to go!
### Grafana Configuration
Credentials are:
username: admin
password: admin
- Create a new password
- You are ready to go!
### Zabbix Configuration
Credentials are:
username: Admin
password: zabbix

- You are ready to go!
### Socks Proxy Configuration

If you don't want to mess with your hosts file you can configure SOCKS proxy to remote server.
```bash
ssh -D 1080 username@remote_server_ip
```
- ssh: The command to start the SSH client.
- -D 1080: This part tells the SSH client to set up a SOCKS proxy on local port 1080

#### Install a proxy extention to your web browser
- Search for a proxy extension like "SwitchyOmega" or "Proxy SwitchySharp" in chrome or "Foxy Proxy". in Firefox.

#### Configure the Extension:

- After installing the extension, open its options or settings page.

- Create a new profile or proxy rule.

- Set the proxy type to SOCKS5 and enter the Server as 127.0.0.1 or remote_server_ip and Port as 1080.

###
## Usage
- Go to https://tools.local to access the dashboard
## Features

## Contributing

A special thank you to Shellnoq, whose insightful request inspired the inception of this project. Your vision for simplifying complex systems has been a guiding light for us all, and your support has been immensely appreciated.

## License

MIT License

Copyright (c) 2024 badtux66

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Contact
