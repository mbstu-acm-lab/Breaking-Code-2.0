#!/bin/bash
#
# Set wallpaper on Ubuntu (GNOME desktop)
#
# Expects wall.jpg to be in the same directory as this script
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WALLPAPER_PATH="$SCRIPT_DIR/wall.jpg"

# Check if wallpaper file exists
if [ ! -f "$WALLPAPER_PATH" ]; then
    echo -e "${RED}ERROR: Wallpaper file not found: $WALLPAPER_PATH${NC}"
    echo "Please ensure wall.jpg is in the same directory as this script."
    read -p "Press Enter to exit..."
    exit 1
fi

echo -e "${YELLOW}Setting wallpaper to: $WALLPAPER_PATH${NC}"

# Detect desktop environment and set wallpaper accordingly
if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] || [ "$XDG_CURRENT_DESKTOP" = "ubuntu:GNOME" ]; then
    # GNOME/Ubuntu
    gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_PATH"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_PATH"
    gsettings set org.gnome.desktop.background picture-options 'zoom'
    echo -e "${GREEN}Wallpaper changed successfully (GNOME)!${NC}"
elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
    # KDE Plasma
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
        var allDesktops = desktops();
        for (i=0;i<allDesktops.length;i++) {
            d = allDesktops[i];
            d.wallpaperPlugin = 'org.kde.image';
            d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
            d.writeConfig('Image', 'file://$WALLPAPER_PATH');
        }
    "
    echo -e "${GREEN}Wallpaper changed successfully (KDE)!${NC}"
elif [ "$XDG_CURRENT_DESKTOP" = "XFCE" ]; then
    # XFCE
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$WALLPAPER_PATH"
    echo -e "${GREEN}Wallpaper changed successfully (XFCE)!${NC}"
else
    echo -e "${YELLOW}Desktop environment not recognized: $XDG_CURRENT_DESKTOP${NC}"
    echo "Attempting to set with feh (requires feh to be installed)..."
    if command -v feh &> /dev/null; then
        feh --bg-scale "$WALLPAPER_PATH"
        echo -e "${GREEN}Wallpaper changed successfully (feh)!${NC}"
    else
        echo -e "${RED}ERROR: Unable to set wallpaper. Please install feh or set manually.${NC}"
        exit 1
    fi
fi

echo ""
read -p "Press Enter to exit..."
