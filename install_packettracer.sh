#!/bin/bash

# Output colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Automated Packet Tracer Installer for Arch Linux (CachyOS) ===${NC}"

# Check if user is root (makepkg should not be run as root)
if [ "$EUID" -eq 0 ]; then
  echo -e "${RED}ERROR: Please do not run this script as root.${NC}"
  echo "'makepkg' should not be run as root. The script will ask for your sudo password when needed."
  exit 1
fi

# Warning about the .deb file
echo -e "${YELLOW}IMPORTANT: Due to Cisco's license, you must have downloaded the .deb installer manually from NetAcad.${NC}"
echo "The AUR package expects a specific version. Ensure you have the latest version compatible with AUR."
echo ""

# Request file path
read -p "Please drag the .deb file into this terminal or type the full path: " DEB_PATH

# Remove single quotes and expand ~
DEB_PATH=$(echo "$DEB_PATH" | tr -d "'")
DEB_PATH="${DEB_PATH/#\~/$HOME}"

if [ ! -f "$DEB_PATH" ]; then
    echo -e "${RED}File not found: $DEB_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}File found: $DEB_PATH${NC}"

# Install build dependencies
echo -e "${GREEN}Installing build dependencies (base-devel, git, fuse2)...${NC}"
if ! sudo pacman -S --needed --noconfirm base-devel git fuse2; then
    echo -e "${RED}Failed to install dependencies.${NC}"
    exit 1
fi

# Prepare temporary directory
WORK_DIR=$(mktemp -d)
echo -e "${GREEN}Creating temporary working environment at: $WORK_DIR${NC}"
cd "$WORK_DIR" || exit 1

# Clone AUR repository
echo -e "${GREEN}Cloning AUR repository (packettracer)...${NC}"
if ! git clone https://aur.archlinux.org/packettracer.git; then
    echo -e "${RED}Failed to clone AUR repository.${NC}"
    exit 1
fi

cd packettracer || exit 1

# Copy .deb file to build directory
FILENAME=$(basename "$DEB_PATH")
echo -e "${GREEN}Copying $FILENAME to build directory...${NC}"
cp "$DEB_PATH" .

# --- PATCH PKGBUILD ---
echo -e "${GREEN}Applying PKGBUILD fixes (symlink and .desktop)...${NC}"
# Remove the last line (package function closing brace)
sed -i '$d' PKGBUILD
# Add fix commands and close the function
cat <<EOF >> PKGBUILD
    
    # Fixes by install script
    mkdir -p "\${pkgdir}/usr/bin"
    
    # Find the binary dynamically
    echo "Searching for PacketTracer binary..."
    BIN_PATH=\$(find "\${pkgdir}/usr/lib/packettracer" -type f \( -name "PacketTracer" -o -name "packettracer" -o -name "*.AppImage" \) | head -n 1)
    
    if [ -z "\$BIN_PATH" ]; then
        echo "ERROR: Could not find PacketTracer binary."
        echo "Content of \${pkgdir}/usr/lib/packettracer:"
        find "\${pkgdir}/usr/lib/packettracer" -maxdepth 3
        exit 1
    fi
    
    echo "Binary found at: \$BIN_PATH"
    chmod +x "\$BIN_PATH"

    # Create symlink
    LINK_TARGET=\${BIN_PATH#\${pkgdir}}
    ln -s "\$LINK_TARGET" "\${pkgdir}/usr/bin/packettracer"
    
    # Fix desktop file paths
    if [ -d "\${pkgdir}/usr/share/applications" ]; then
        find "\${pkgdir}/usr/share/applications" -name "*.desktop" -exec sed -i 's|/opt/pt|/usr/lib/packettracer|g' {} +
        # Adjust Exec to use the command from path
        find "\${pkgdir}/usr/share/applications" -name "*.desktop" -exec sed -i 's|^Exec=.*|Exec=packettracer|g' {} +
    fi
}
EOF
# --- END PATCH ---

echo -e "${GREEN}Starting compilation and installation (makepkg)...${NC}"
echo -e "${YELLOW}Note: If validity check fails (sha256sums), verify if your .deb version matches the AUR package version.${NC}"

# Run makepkg
if makepkg -sic; then
    echo -e "${GREEN}=== Installation Successfully Completed! ===${NC}"

    # Ensure correct permissions for config directory (EULA fix)
    PT_CONFIG_DIR="$HOME/.local/.packettracer"
    if [ -d "$PT_CONFIG_DIR" ]; then
        echo "Adjusting configuration directory permissions..."
        sudo chown -R "$USER:$USER" "$PT_CONFIG_DIR"
    fi

    echo "You can start Packet Tracer by typing 'packettracer' in the terminal or searching in the application menu."
else
    echo -e "${RED}=== Installation Failed ===${NC}"
    echo "Check the error messages above. Common issues: incorrect filename or .deb version mismatch with AUR."
fi

# Cleanup
cd "$HOME"
