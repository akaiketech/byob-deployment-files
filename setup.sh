#!/bin/bash

# This script sets up a deployment environment:
# - Ensuring it is run with root privileges
# - Updating the package list
# - Installing necessary dependencies
# - Setting up Docker, AWS CLI, and Python 3.12
# - Printing the installed versions

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' 
TICK="${GREEN}✓${NC}"

print_section() {
    echo -e "\n${BLUE}==>${NC} $1..."
}

print_success() {
    echo -e "${TICK} $1"
}

check_command() {
    if command -v $1 >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

print_section "Updating package list"
apt-get update
print_success "Package list updated"

print_section "Installing dependencies"
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common
print_success "Dependencies installed"

print_section "Setting up Docker"
if check_command docker; then
    print_success "Docker is already installed"
else
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker $SUDO_USER
    rm get-docker.sh
    print_success "Docker and Docker Compose installed successfully"
fi

print_section "Setting up AWS CLI"
apt-get install -y unzip
unzip awscliv2.zip
if check_command aws; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    print_success "AWS CLI updated successfully"
else
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
    print_success "AWS CLI installed successfully"
fi
rm -rf aws awscliv2.zip

print_section "Setting up Python 3.12 and pip"
if python3.12 --version >/dev/null 2>&1; then
    print_success "Python 3.12 is already installed"
else
    add-apt-repository -y ppa:deadsnakes/ppa
    apt-get update
    apt-get install -y python3.12 python3.12-venv python3.12-dev
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1
    update-alternatives --set python3 /usr/bin/python3.12
    
    print_success "Python 3.12 installed successfully"
fi

if python3.12 -m pip --version >/dev/null 2>&1; then
    print_success "pip for Python 3.12 is already installed"
else
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3.12
    print_success "pip for Python 3.12 installed successfully"
fi

print_section "Adding current user to Docker group"
if groups $USER | grep &>/dev/null '\bdocker\b'; then
    print_success "User is already in the Docker group"
else
    sudo usermod -aG docker $USER
    newgrp docker
    print_success "User added to Docker group successfully"
fi


echo -e "\n${GREEN}✓ All installations completed successfully!${NC}"

echo -e "\n${BLUE}Installed versions:${NC}"
echo -e "Docker: $(docker --version)"
echo -e "Docker Compose: $(docker compose version)"
echo -e "AWS CLI: $(aws --version)"
echo -e "Python: $(python3 --version)"
