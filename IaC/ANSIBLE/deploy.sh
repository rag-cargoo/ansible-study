#!/bin/bash
# This script runs the deploy-all.yml playbook.
# Additional arguments can be passed to ansible-playbook (e.g., ./deploy.sh --check)
ansible-playbook playbooks/deploy-all.yml "$@"
