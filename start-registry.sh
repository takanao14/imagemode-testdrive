#!/usr/bin/env bash

# If registry-data directory does not exist, create it
if [ ! -d "registry-data" ]; then
  echo "Creating registry-data directory..."
  mkdir -p registry-data
fi

# Check if the registry container is already running
is_running() {
  container inspect registry | jq -e '.[0].status == "running"'> /dev/null 2>&1
}

is_running
state=$?

# If the registry container is not running, start it
if [[ $state -ne 0 ]]; then
    echo "Starting local registry container..."
    container run -d --rm --name registry \
        -v ${PWD}/registry-data:/var/lib/registry \
        mirror.gcr.io/registry:3
fi

# If podman-conf directory does not exist, create it
if [ ! -d "podman-conf" ]; then
  echo "Creating podman-conf directory..."
  mkdir -p container/podman-conf
fi

# Get the IP address of the registry container
REGISTRY_IPADDR=$(container inspect registry | jq -jr '.[].networks[].address | split("/")[0]')
echo "Local registry IP address: ${REGISTRY_IPADDR}:5000"

# Create local.conf for podman to use the local registry
cat <<EOF > container/podman-conf/local.conf
[[registry]]
location="${REGISTRY_IPADDR}:5000"
insecure=true
EOF

# Copy local.conf to podman machine and restart podman machine
podman machine cp container/podman-conf/local.conf podman-machine-default:/etc/containers/registries.conf.d/local.conf

echo "Restarting podman machine"
podman machine stop >/dev/null && echo "Podman machine stopped"
podman machine start > /dev/null && echo "Podman machine restarted"
