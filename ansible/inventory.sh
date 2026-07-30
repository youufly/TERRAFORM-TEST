#!/bin/bash
set -euo pipefail
IP=$(cd ../envs/dev-aws && terraform output -raw url_publique | sed -e 's|http://||')
CLE="$(pwd)/../envs/dev-aws/tpiac-dev-key.pem"
cat << INVENTORY
[web]
$IP ansible_user=ubuntu ansible_ssh_private_key_file=$CLE ansible_ssh_common_args='-o StrictHostKeyChecking=no'
INVENTORY
