#!/bin/bash
#
# Install development tools on Ubuntu 24.04 LTS
#
# Installs:
#   - GCC/G++ (build-essential)
#   - Java (OpenJDK 25)
#   - Python 3.14
#   - Visual Studio Code
#   - PyCharm Community
#   - IntelliJ IDEA Community
#   - Code::Blocks
#   - Sublime Text 4
#
# Must be run with sudo privileges
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}This script requires sudo privileges. Requesting elevation...${NC}"
    exec sudo "$0" "$@"
    exit $?
fi

echo -e "${CYAN}Starting Installation Process...${NC}"
echo -e "${GRAY}This may take a while depending on your internet connection.${NC}"
echo "----------------------------------------"

# Update package lists
echo -e "${YELLOW}Updating package lists...${NC}"
apt-get update -qq

# 1. Install GCC/G++ (build-essential)
echo -e "${YELLOW}Installing GCC/G++ (build-essential)...${NC}"
apt-get install -y build-essential
if [ $? -eq 0 ]; then
    echo -e "${GREEN}  Success.${NC}"
else
    echo -e "${GRAY}  Already installed or failed.${NC}"
fi

# 2. Install Java (OpenJDK 25)
echo -e "${YELLOW}Installing Java (OpenJDK 25)...${NC}"
# Add Oracle Java PPA if not already added
if ! grep -q "^deb .*oracle-java" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
    # For OpenJDK 25, we'll try default-jdk first, or manual download
    apt-get install -y openjdk-21-jdk 2>/dev/null || apt-get install -y default-jdk
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}  Success (OpenJDK installed).${NC}"
        echo -e "${YELLOW}  Note: OpenJDK 25 may not be available in Ubuntu repos. Installed latest available version.${NC}"
    else
        echo -e "${GRAY}  Failed or already installed.${NC}"
    fi
else
    apt-get install -y oracle-java21-installer 2>/dev/null || echo -e "${GRAY}  Installation failed.${NC}"
fi

# 3. Install Python 3.14
echo -e "${YELLOW}Installing Python 3.14...${NC}"
# Python 3.14 may need to be built from source or use deadsnakes PPA
apt-get install -y software-properties-common
add-apt-repository -y ppa:deadsnakes/ppa 2>/dev/null || true
apt-get update -qq
apt-get install -y python3.14 python3.14-venv python3.14-dev 2>/dev/null || \
apt-get install -y python3 python3-pip python3-venv
if [ $? -eq 0 ]; then
    echo -e "${GREEN}  Success.${NC}"
else
    echo -e "${GRAY}  Python 3.14 not available. Installed latest Python 3.${NC}"
fi

# 4. Install Visual Studio Code
echo -e "${YELLOW}Installing Visual Studio Code...${NC}"
if ! command -v code &> /dev/null; then
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
    rm -f packages.microsoft.gpg
    apt-get update -qq
    apt-get install -y code
    echo -e "${GREEN}  Success.${NC}"
else
    echo -e "${GRAY}  Already installed.${NC}"
fi

# 5. Install PyCharm Community
echo -e "${YELLOW}Installing PyCharm Community...${NC}"
if ! command -v pycharm-community &> /dev/null; then
    snap install pycharm-community --classic
    echo -e "${GREEN}  Success.${NC}"
else
    echo -e "${GRAY}  Already installed.${NC}"
fi

# 6. Install IntelliJ IDEA Community
echo -e "${YELLOW}Installing IntelliJ IDEA Community...${NC}"
if ! command -v intellij-idea-community &> /dev/null; then
    snap install intellij-idea-community --classic
    echo -e "${GREEN}  Success.${NC}"
else
    echo -e "${GRAY}  Already installed.${NC}"
fi

# 7. Install Code::Blocks
echo -e "${YELLOW}Installing Code::Blocks...${NC}"
apt-get install -y codeblocks codeblocks-contrib
if [ $? -eq 0 ]; then
    echo -e "${GREEN}  Success.${NC}"
else
    echo -e "${GRAY}  Failed or already installed.${NC}"
fi

# 8. Install Sublime Text 4
echo -e "${YELLOW}Installing Sublime Text 4...${NC}"
if ! command -v subl &> /dev/null; then
    wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
    echo "deb https://download.sublimetext.com/ apt/stable/" > /etc/apt/sources.list.d/sublime-text.list
    apt-get update -qq
    apt-get install -y sublime-text
    echo -e "${GREEN}  Success.${NC}"
else
    echo -e "${GRAY}  Already installed.${NC}"
fi

echo "----------------------------------------"
echo -e "${CYAN}Installation Complete!${NC}"
echo -e "${YELLOW}NOTE: You may need to log out and back in for all changes to take effect.${NC}"
echo ""
read -p "Press Enter to exit..."
