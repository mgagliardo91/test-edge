#!/bin/bash

# Locate the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIO_DIR="/nio"

# Load the .env file if it exists
ENV_FILE="$SCRIPT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
  # Export environment variables from the .env file
  set -a
  source "$ENV_FILE"
  set +a
fi

install_remoteit() {
  if [ ! -d "/nio/remoteit" ]; then
    echo "Creating remoteit directory"
    mkdir -p $NIO_DIR/remoteit
    ln -s $NIO_DIR/remoteit /etc/remoteit
  fi

  echo "Installing remoteit"
  R3_REGISTRATION_CODE="$R3_REGISTRATION_CODE" sh -c "$(curl -L https://downloads.remote.it/remoteit/install_agent.sh)"
}

install_docker() {
  if [ -x "$(command -v docker)" ]; then
    return
  fi
  echo "Installing docker"

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  apt-get update
  apt-get install -y docker-ce
  systemctl enable docker
  systemctl start docker
  usermod -aG docker nio
}

initialize_nio() {
  echo "Initializing nio"

  # deploy
  mkdir -p $NIO_DIR/deploy

  if [ ! -f "$NIO_DIR/run-edge.sh" ]; then
    echo "Creating run-edge.sh service"
    curl -o "$NIO_DIR/run-edge.sh" https://raw.githubusercontent.com/mgagliardo91/test-edge/main/run-edge.sh
    chmod +x "$NIO_DIR/run-edge.sh"

    cat <<EOF | tee /etc/systemd/system/run-edge.service
[Unit]
Description=Run Edge Script Service
After=network.target

[Service]
ExecStart=/nio/run-edge.sh
Restart=always
User=root
WorkingDirectory=/nio

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload           # Reload systemd to recognize the new service
    systemctl enable run-edge.service # Enable the service to start on boot
    systemctl start run-edge.service  # Start the service immediately
  fi
}

install_docker
initialize_nio
install_remoteit