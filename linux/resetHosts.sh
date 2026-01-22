#!/bin/bash
#
# Reset /etc/hosts file to default state on Ubuntu
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

echo "========================================"
echo -e "${RED}WARNING: This will reset the hosts file to its default state!${NC}"
echo -e "${YELLOW}All custom entries will be lost.${NC}"
echo "========================================"
read -p "Do you want to continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${CYAN}Operation cancelled.${NC}"
    exit 0
fi

HOSTS_FILE="/etc/hosts"

echo ""
echo -e "${YELLOW}Creating backup...${NC}"
cp "$HOSTS_FILE" "$HOSTS_FILE.bak"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Backup saved to: $HOSTS_FILE.bak${NC}"
else
    echo -e "${YELLOW}WARNING: Failed to create backup.${NC}"
fi

echo -e "${YELLOW}Writing default hosts file...${NC}"

# Write default hosts file
cat > "$HOSTS_FILE" <<'EOF'
127.0.0.1	localhost
127.0.1.1	ubuntu

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}SUCCESS: Hosts file has been reset to default.${NC}"
else
    echo ""
    echo -e "${RED}ERROR: Failed to write hosts file.${NC}"
    exit 1
fi

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
echo -e "${CYAN}Operation complete.${NC}"
echo ""
read -p "Press Enter to exit..."
