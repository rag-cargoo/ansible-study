#!/bin/bash

# Script to connect to the bastion host via SSH

set -e

BASTION_IP=$1
SSH_KEY="$HOME/.aws/key/test_key.pem"
USER="ubuntu"

if [ -z "$BASTION_IP" ]; then
  echo "Usage: $0 <BASTION_PUBLIC_IP>"
  exit 1
fi

echo "Connecting to bastion host: ${USER}@${BASTION_IP}"

ssh -i "${SSH_KEY}" "${USER}@${BASTION_IP}"
