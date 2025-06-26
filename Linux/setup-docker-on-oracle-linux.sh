#!/bin/bash
# Docker Installation on Oracle Linux

# First, check Oracle Linux version
echo "Checking Oracle Linux version..."
cat /etc/oracle-release

# Method 1: Add Docker CE repository (Recommended)
echo "Adding Docker CE repository..."
sudo dnf install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker CE
echo "Installing Docker CE..."
sudo dnf install -y docker-ce docker-ce-cli containerd.io

# Alternative Method 2: If above fails, try Oracle's container-tools module
# sudo dnf module install -y container-tools

# Start and enable Docker
echo "Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
echo "Adding user to docker group..."
sudo groupadd docker 2>/dev/null || true  # Create group if it doesn't exist
sudo usermod -aG docker $USER

# Install Docker Compose (separate installation)
echo "Installing Docker Compose..."
DOCKER_COMPOSE_VERSION="2.24.0"
sudo curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create symlink for easier access
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Verify installations
echo "Verifying Docker installation..."
sudo docker --version
sudo docker-compose --version

# Test Docker (optional)
echo "Testing Docker with hello-world..."
sudo docker run hello-world

echo ""
echo "✅ Docker installation completed!"
echo "⚠️  IMPORTANT: Please logout and login again for group changes to take effect"
echo "Then you can run docker commands without sudo"