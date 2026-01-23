#!/bin/bash
# Psono AWS Bootstrap - Zero Touch
set -e

# Log output
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting Psono Deployment..."

# Install Git
apt-get update -qq
apt-get install -y -qq git

# Clone and Run Setup
cd /opt
git clone ${repository_url} psono
cd psono
chmod +x scripts/setup.sh

# Run the master setup script
./scripts/setup.sh

echo "Deployment Finished!"
