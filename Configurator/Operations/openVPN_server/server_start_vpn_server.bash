#!/bin/bash

WORKING_DIR="{{ working_dir }}"

# Check if the container named 'openvpn-server' exists
if [ "$(docker ps -a --filter "name=openvpn-server" --format '{{.Names}}')" != "openvpn-server" ]; then
    echo "Container 'openvpn-server' not found. Creating and starting..."
    docker run -d --name=openvpn-server \
        -v "${WORKING_DIR}:/etc/openvpn" \
        -p 1194:1194/udp \
        --cap-add=NET_ADMIN \
        --restart unless-stopped \
        kylemanna/openvpn
else
    docker start openvpn-server
fi