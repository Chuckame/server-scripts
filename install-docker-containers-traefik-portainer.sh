#!/usr/bin/env bash
#
# Add containers :
# - proxy (traefik)
# - web container manager (Portainer)
#
# Use like this : ./install-docker-containers-traefik-portainer.sh --mail=mymail@gmail.com --domain=mydomain.com --appKey=xxxxxxxxx --appSecret=xxxxxxx --consumerKey=xxxxx
#
# To get OVH credentials, go to this link, and keep preciously application_key, application secret & consumer key :
# https://api.ovh.com/createToken/?GET=/domain/zone/*/record&POST=/domain/zone/*/record&PUT=/domain/zone/*/record/*&DELETE=/domain/zone/*/record/*&POST=/domain/zone/*/refresh
setup_args() {
  for i in "$@"; do
    case $i in
    --mail=*)
      EMAIL="${i#*=}"
      shift # past argument=value
      ;;
    --domain=*)
      DOMAIN="${i#*=}"
      shift # past argument=value
      ;;
    --appKey=*)
      OVH_APPLICATION_KEY="${i#*=}"
      shift # past argument=value
      ;;
    --appSecret=*)
      OVH_APPLICATION_SECRET="${i#*=}"
      shift # past argument=value
      ;;
    --consumerKey=*)
      OVH_CONSUMER_KEY="${i#*=}"
      shift # past argument=value
      ;;
    *)
      # unknown option
      ;;
    esac
  done
  echo "EMAIL                  = ${EMAIL}"
  echo "DOMAIN                 = ${DOMAIN}"
  echo "OVH_APPLICATION_KEY    = ${OVH_APPLICATION_KEY}"
  echo "OVH_APPLICATION_SECRET = ${OVH_APPLICATION_SECRET}"
  echo "OVH_CONSUMER_KEY       = ${OVH_CONSUMER_KEY}"
  if [[ ! "$EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+.[A-Za-z]{2,6}$ || ! "$DOMAIN" =~ ^[a-z0-9\-]+\.[a-z0-9\-]{2,}$ || ! "$OVH_APPLICATION_KEY" =~ ^[a-zA-Z0-9]+$ || ! "$OVH_APPLICATION_SECRET" =~ ^[a-zA-Z0-9]+$ || ! "$OVH_CONSUMER_KEY" =~ ^[a-zA-Z0-9]+$ ]]; then
    echo "This script must be used like this: ./install-docker-containers-traefik-portainer.sh --mail=mymail@gmail.com --domain=mydomain.com --appKey=xxxxxxxxx --appSecret=xxxxxxx --consumerKey=xxxxx"
    exit 1
  fi
}

create_apps_config() {
  cat >traefik.toml <<EOF
defaultEntryPoints = ["http", "https"]

[entryPoints]
  [entryPoints.http]
  address = ":80"
    [entryPoints.http.redirect]
    entryPoint = "https"
  [entryPoints.https]
  address = ":443"
    [entryPoints.https.tls]

[acme]
email = "${EMAIL}"
storageFile = "/etc/traefik/acme/acme.json"
entryPoint = "https"
OnHostRule = true
onDemand = true
  [acme.dnsChallenge]
  provider = "ovh"
  delayBeforeCheck = 0
  resolvers = ["1.1.1.1:53", "8.8.8.8:53"]

[[acme.domains]]
  main = "*.${DOMAIN}"
  sans = ["${DOMAIN}"]

[docker]
endpoint = "unix:///var/run/docker.sock"
domain = "${DOMAIN}"
watch = true
exposedbydefault = true
EOF
  cat >docker-compose.yaml <<EOF
version: '2'

services:
  proxy:
    image: traefik
    networks:
      - traefik
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "$PWD/traefik.toml:/etc/traefik/traefik.toml"
      - "$PWD/acme:/etc/traefik/acme"
      - /var/run/docker.sock:/var/run/docker.sock
    restart: unless-stopped
    labels:
      - "traefik.frontend.rule=Host:traefik.${DOMAIN}"
      - "traefik.port=8080"
      - "traefik.backend=traefik"
    environment:
      - OVH_ENDPOINT=ovh-eu
      - OVH_APPLICATION_KEY=${OVH_APPLICATION_KEY}
      - OVH_APPLICATION_SECRET=${OVH_APPLICATION_SECRET}
      - OVH_CONSUMER_KEY=${OVH_CONSUMER_KEY}

  portainer:
    image: portainer/portainer
    networks:
      - traefik
    labels:
      - "traefik.frontend.rule=Host:portainer.${DOMAIN}"
      - "traefik.port=9000"
      - "traefik.backend=portainer"
    volumes:
        - "/var/run/docker.sock:/var/run/docker.sock"
    restart: unless-stopped

networks:
  traefik:
    external:
      name: traefik
EOF
}

install_apps_stack() {
  mkdir server-base-docker-config
  cd server-base-docker-config
  create_apps_config
  docker network create traefik
  docker-compose up -d
  cd ..
}

main() {
  setup_args $@
  install_apps_stack
}

main $@
