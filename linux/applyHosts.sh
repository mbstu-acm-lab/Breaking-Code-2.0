#!/bin/bash
#
# Apply custom hosts file to system on Ubuntu
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

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_HOSTS="$SCRIPT_DIR/hosts"
TARGET_HOSTS="/etc/hosts"

# Check if source hosts file exists
if [ ! -f "$SOURCE_HOSTS" ]; then
    echo -e "${RED}ERROR: hosts file not found in current directory: $SOURCE_HOSTS${NC}"
    echo "Please ensure the hosts file is in the same directory as this script."
    read -p "Press Enter to exit..."
    exit 1
fi

echo "========================================"
echo "This will replace the system hosts file with:"
echo "$SOURCE_HOSTS"
echo ""
echo "Target location:"
echo "$TARGET_HOSTS"
echo "========================================"
read -p "Do you want to continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${CYAN}Operation cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Creating backup...${NC}"
cp "$TARGET_HOSTS" "$TARGET_HOSTS.bak"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Backup saved to: $TARGET_HOSTS.bak${NC}"
else
    echo -e "${YELLOW}WARNING: Failed to create backup.${NC}"
fi

echo -e "${YELLOW}Copying new hosts file...${NC}"
cp "$SOURCE_HOSTS" "$TARGET_HOSTS"
if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to copy hosts file.${NC}"
    read -p "Press Enter to exit..."
    exit 1
fi

# Set proper permissions
chmod 644 "$TARGET_HOSTS"

echo -e "${YELLOW}Flushing DNS cache...${NC}"
# Ubuntu uses systemd-resolved
if command -v systemd-resolve &> /dev/null; then
    systemd-resolve --flush-caches 2>/dev/null
elif command -v resolvectl &> /dev/null; then
    resolvectl flush-caches 2>/dev/null
fi

# Also restart systemd-resolved service
systemctl restart systemd-resolved 2>/dev/null

echo ""
echo -e "${GREEN}SUCCESS: System hosts file has been updated!${NC}"
echo -e "${YELLOW}You may need to restart your browser for changes to take effect.${NC}"
echo ""
read -p "Press Enter to exit..."
