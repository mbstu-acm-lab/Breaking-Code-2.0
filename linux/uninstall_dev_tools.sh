#!/bin/bash
#
# Uninstall development tools from Ubuntu 24.04 LTS
#
# Removes:
#   - GCC/G++ (build-essential)
#   - Java (OpenJDK)
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
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}This script requires sudo privileges. Requesting elevation...${NC}"
    exec sudo "$0" "$@"
    exit $?
fi

echo -e "${RED}========================================${NC}"
echo -e "${RED}WARNING: This will uninstall development tools and delete their directories!${NC}"
echo -e "${YELLOW}This operation cannot be undone.${NC}"
echo -e "${RED}========================================${NC}"
read -p "Do you want to continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${CYAN}Operation cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${CYAN}Starting AUTO-UNINSTALL process...${NC}"
uninstalled_apps=()

# 1. Uninstall Visual Studio Code
echo -e "${YELLOW}Uninstalling Visual Studio Code...${NC}"
if command -v code &> /dev/null; then
    apt-get remove -y code
    apt-get purge -y code
    echo -e "${GREEN}  Uninstalled.${NC}"
    uninstalled_apps+=("Visual Studio Code")
else
    echo -e "${GRAY}  Not installed.${NC}"
fi

# 2. Uninstall PyCharm Community
echo -e "${YELLOW}Uninstalling PyCharm Community...${NC}"
if snap list | grep -q pycharm-community; then
    snap remove pycharm-community
    echo -e "${GREEN}  Uninstalled.${NC}"
    uninstalled_apps+=("PyCharm Community")
else
    echo -e "${GRAY}  Not installed.${NC}"
fi

# 3. Uninstall IntelliJ IDEA Community
echo -e "${YELLOW}Uninstalling IntelliJ IDEA Community...${NC}"
if snap list | grep -q intellij-idea-community; then
    snap remove intellij-idea-community
    echo -e "${GREEN}  Uninstalled.${NC}"
    uninstalled_apps+=("IntelliJ IDEA Community")
else
    echo -e "${GRAY}  Not installed.${NC}"
fi

# 4. Uninstall Code::Blocks
echo -e "${YELLOW}Uninstalling Code::Blocks...${NC}"
if dpkg -l | grep -q codeblocks; then
    apt-get remove -y codeblocks codeblocks-contrib
    apt-get purge -y codeblocks codeblocks-contrib
    echo -e "${GREEN}  Uninstalled.${NC}"
    uninstalled_apps+=("Code::Blocks")
else
    echo -e "${GRAY}  Not installed.${NC}"
fi

# 5. Uninstall Sublime Text
echo -e "${YELLOW}Uninstalling Sublime Text...${NC}"
if command -v subl &> /dev/null; then
    apt-get remove -y sublime-text
    apt-get purge -y sublime-text
    echo -e "${GREEN}  Uninstalled.${NC}"
    uninstalled_apps+=("Sublime Text")
else
    echo -e "${GRAY}  Not installed.${NC}"
fi

# 6. Uninstall Python 3.14
echo -e "${YELLOW}Uninstalling Python 3.14...${NC}"
if command -v python3.14 &> /dev/null; then
    apt-get remove -y python3.14 python3.14-venv python3.14-dev
    apt-get purge -y python3.14 python3.14-venv python3.14-dev
    echo -e "${GREEN}  Uninstalled.${NC}"
    uninstalled_apps+=("Python 3.14")
else
    echo -e "${GRAY}  Not installed.${NC}"
fi

# 7. Uninstall Java
echo -e "${YELLOW}Uninstalling Java (OpenJDK)...${NC}"
if command -v java &> /dev/null; then
    apt-get remove -y 'openjdk-*' default-jdk
    apt-get purge -y 'openjdk-*' default-jdk
    echo -e "${GREEN}  Uninstalled.${NC}"
    uninstalled_apps+=("Java OpenJDK")
else
    echo -e "${GRAY}  Not installed.${NC}"
fi

# 8. Uninstall build-essential (GCC/G++)
echo -e "${YELLOW}Uninstalling build-essential (GCC/G++)...${NC}"
if dpkg -l | grep -q build-essential; then
    apt-get remove -y build-essential
    apt-get purge -y build-essential
    echo -e "${GREEN}  Uninstalled.${NC}"
    uninstalled_apps+=("build-essential")
else
    echo -e "${GRAY}  Not installed.${NC}"
fi

echo ""
echo "----------------------------------------"
if [ ${#uninstalled_apps[@]} -gt 0 ]; then
    echo -e "${GREEN}Uninstalled applications:${NC}"
    for app in "${uninstalled_apps[@]}"; do
        echo -e "${GRAY}  - $app${NC}"
    done
else
    echo -e "${YELLOW}No matching applications were found to uninstall.${NC}"
fi

echo ""
echo -e "${YELLOW}Proceeding to CLEANUP in 5 seconds...${NC}"
echo -e "${GRAY}(Press Ctrl+C to cancel)${NC}"
sleep 5

# Cleanup directories
echo ""
echo -e "${CYAN}Cleaning directories...${NC}"
deleted_count=0

cleanup_paths=(
    "$HOME/.vscode"
    "$HOME/.config/Code"
    "$HOME/.config/JetBrains"
    "$HOME/.local/share/JetBrains"
    "$HOME/.PyCharm*"
    "$HOME/.IntelliJIdea*"
    "$HOME/.config/codeblocks"
    "$HOME/.config/sublime-text-3"
    "$HOME/.config/sublime-text"
    "/opt/sublime_text"
)

for path_pattern in "${cleanup_paths[@]}"; do
    for path in $path_pattern; do
        if [ -e "$path" ]; then
            echo -e "${MAGENTA}  Deleting: $path${NC}"
            rm -rf "$path" 2>/dev/null && ((deleted_count++)) || echo -e "${YELLOW}  Could not delete: $path${NC}"
        fi
    done
done

# Run autoremove to clean up dependencies
echo ""
echo -e "${YELLOW}Running apt autoremove to clean up unused packages...${NC}"
apt-get autoremove -y
apt-get autoclean

echo ""
echo "----------------------------------------"
echo -e "${GREEN}Cleanup complete. Deleted $deleted_count item(s).${NC}"
echo -e "${YELLOW}You may want to restart your computer to complete the cleanup.${NC}"
echo ""
read -p "Press Enter to exit..."
