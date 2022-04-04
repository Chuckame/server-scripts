#!/usr/bin/env bash
#
# Install portainer
#

docker volume create portainer_data
docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce

rsync -rvz -e 'ssh -p 7777' --progress root@chuckame.fr:/data/pptp-vpn-data /var/lib/docker/volumes/old_server_data/_data/
