#!/bin/bash
#
# Create a new user with sudo privileges on Ubuntu
#
# Must be run with sudo privileges
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}This script requires sudo privileges. Requesting elevation...${NC}"
    exec sudo "$0" "$@"
    exit $?
fi

USERNAME="BreakingCode2.0"
PASSWORD="csembstu"

echo "========================================"
echo -e "${RED}WARNING: This will create a user account with sudo privileges!${NC}"
echo "Username: $USERNAME"
echo "========================================"
read -p "Do you want to continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${CYAN}Operation cancelled.${NC}"
    exit 0
fi

# Check if user already exists
if id "$USERNAME" &>/dev/null; then
    echo -e "${YELLOW}User '$USERNAME' already exists.${NC}"
    read -p "Press Enter to exit..."
    exit 0
fi

echo ""
echo -e "${YELLOW}Creating user...${NC}"
# Create user with home directory
useradd -m -s /bin/bash "$USERNAME"
if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to create user.${NC}"
    read -p "Press Enter to exit..."
    exit 1
fi

# Set password
echo "$USERNAME:$PASSWORD" | chpasswd
if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to set password.${NC}"
    read -p "Press Enter to exit..."
    exit 1
fi

echo -e "${YELLOW}Adding to sudo group...${NC}"
# Add user to sudo group
usermod -aG sudo "$USERNAME"
if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to add user to sudo group.${NC}"
    read -p "Press Enter to exit..."
    exit 1
fi

echo ""
echo -e "${GREEN}SUCCESS: User '$USERNAME' has been created and added to sudo group.${NC}"
echo -e "${GRAY}The user can now use 'sudo' to run commands with administrative privileges.${NC}"
echo ""
read -p "Press Enter to exit..."
