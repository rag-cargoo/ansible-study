#!/bin/bash

# Monitoring SSH Tunneling Script (Grafana & Prometheus)

# Usage: ./connect_monitoring_tunnel.sh <BASTION_PUBLIC_IP>

BASTION_PUBLIC_IP=$1
MONITORING_PRIVATE_IP="10.0.101.11"
GRAFANA_PORT="3000"
LOCAL_PORT="3000"
SSH_KEY_PATH="$HOME/.aws/key/test_key.pem"
SSH_USER="ubuntu"

if [ -z "$BASTION_PUBLIC_IP" ]; then
  echo "Usage: $0 <BASTION_PUBLIC_IP>"
  echo "Example: $0 54.180.123.45"
  exit 1
fi

echo "Attempting to establish SSH tunnel to Grafana and Prometheus..."
echo "Local: http://localhost:$LOCAL_PORT"
echo "Via Bastion: $SSH_USER@$BASTION_PUBLIC_IP"
echo "To Monitoring Server: $MONITORING_PRIVATE_IP:$GRAFANA_PORT"

# -f: Go to background after authentication
# -N: Do not execute a remote command (useful for just forwarding ports)
ssh -i "$SSH_KEY_PATH" -fN -L "$LOCAL_PORT":"$MONITORING_PRIVATE_IP":"$GRAFANA_PORT" -L 9090:"$MONITORING_PRIVATE_IP":9090 "$SSH_USER"@"$BASTION_PUBLIC_IP"

if [ $? -eq 0 ]; then
  echo "SSH tunnel established successfully in the background."
  echo "You can now access Grafana at http://localhost:$LOCAL_PORT"
  echo "To kill the tunnel, find the ssh process (e.g., ps aux | grep 'ssh -i ...') and kill it."
else
  echo "Failed to establish SSH tunnel."
fi
