#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Logic2 .deb Package Builder${NC}"
echo "================================"

# Check for required tools
echo -e "${YELLOW}Checking dependencies...${NC}"
for tool in curl wget wrestool icotool dpkg-deb; do
    if ! command -v $tool &> /dev/null; then
        echo -e "${RED}Error: $tool is not installed${NC}"
        echo "Please install required packages: curl wget icoutils dpkg-dev"
        exit 1
    fi
done

# Create temporary working directory
WORK_DIR=$(mktemp -d)
echo -e "${YELLOW}Working directory: $WORK_DIR${NC}"

cd "$WORK_DIR"

# Download the latest Logic2 AppImage
echo -e "${YELLOW}Downloading latest Logic2 AppImage...${NC}"
DOWNLOAD_URL="https://logic2api.saleae.com/download?os=linux&arch=x64"
wget -O logic2.AppImage "$DOWNLOAD_URL"
chmod +x logic2.AppImage

# Extract version from filename
ACTUAL_URL=$(curl -sI "$DOWNLOAD_URL" | grep -i "^location:" | awk '{print $2}' | tr -d '\r')
VERSION=$(echo "$ACTUAL_URL" | grep -oP 'Logic-\K[0-9.]+' || echo "2.4.36")
echo -e "${GREEN}Detected version: $VERSION${NC}"

# Download Windows installer for icon extraction
echo -e "${YELLOW}Downloading Windows installer for icon extraction...${NC}"
WIN_URL="https://downloads2.saleae.com/logic2/Logic-${VERSION}-windows-x64.exe"
wget -O logic2-win.exe "$WIN_URL" || {
    echo -e "${RED}Warning: Could not download Windows installer, will create a basic icon${NC}"
    # Create a simple fallback icon if Windows installer not available
    convert -size 256x256 xc:none -font DejaVu-Sans -pointsize 72 -fill '#FF6B35' \
            -gravity center -annotate +0+0 'L' icon.png 2>/dev/null || {
        echo -e "${RED}Error: Could not create fallback icon${NC}"
        exit 1
    }
}

# Extract icon from Windows installer
if [ -f logic2-win.exe ]; then
    echo -e "${YELLOW}Extracting icon from Windows installer...${NC}"
    wrestool -x --output=. --type=14 logic2-win.exe 2>/dev/null || true
    if ls *.ico &>/dev/null; then
        icotool -x *.ico 2>/dev/null || true
        # Find the largest PNG icon
        ICON_FILE=$(ls *_256x256x32.png 2>/dev/null | head -1)
        if [ -n "$ICON_FILE" ]; then
            cp "$ICON_FILE" icon.png
            echo -e "${GREEN}Icon extracted successfully${NC}"
        fi
    fi
fi

# Verify we have an icon
if [ ! -f icon.png ]; then
    echo -e "${RED}Error: No icon file created${NC}"
    exit 1
fi

# Create .deb package structure
echo -e "${YELLOW}Creating .deb package structure...${NC}"
PKG_NAME="saleae-logic2"
PKG_DIR="${PKG_NAME}_${VERSION}_amd64"
mkdir -p "$PKG_DIR/DEBIAN"
mkdir -p "$PKG_DIR/usr/bin"
mkdir -p "$PKG_DIR/usr/share/applications"
mkdir -p "$PKG_DIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$PKG_DIR/usr/lib/saleae-logic2"

# Copy files
cp logic2.AppImage "$PKG_DIR/usr/lib/saleae-logic2/Logic2.AppImage"
chmod +x "$PKG_DIR/usr/lib/saleae-logic2/Logic2.AppImage"
cp icon.png "$PKG_DIR/usr/share/icons/hicolor/256x256/apps/saleae-logic2.png"

# Create wrapper script
cat > "$PKG_DIR/usr/bin/saleae-logic2" << 'EOF'
#!/bin/bash
exec /usr/lib/saleae-logic2/Logic2.AppImage --no-sandbox "$@"
EOF
chmod +x "$PKG_DIR/usr/bin/saleae-logic2"

# Create desktop entry
cat > "$PKG_DIR/usr/share/applications/Logic.desktop" << 'EOF'
[Desktop Entry]
Name=Logic 2
Comment=Saleae Logic Analyzer Software
Exec=/usr/bin/saleae-logic2 %U
Icon=saleae-logic2
Terminal=false
Type=Application
Categories=Development;Electronics;Engineering;
StartupWMClass=Logic
StartupNotify=true
MimeType=x-scheme-handler/logic2;
EOF

# Create control file
INSTALLED_SIZE=$(du -sk "$PKG_DIR/usr" | cut -f1)
cat > "$PKG_DIR/DEBIAN/control" << EOF
Package: saleae-logic2
Version: $VERSION
Section: electronics
Priority: optional
Architecture: amd64
Installed-Size: $INSTALLED_SIZE
Depends: fuse, libfuse2
Maintainer: Saleae <support@saleae.com>
Homepage: https://www.saleae.com
Description: Saleae Logic 2 - Logic Analyzer Software
 Logic 2 is the next-generation software for Saleae logic analyzers.
 It features a modern UI, improved performance, and powerful analysis tools.
 .
 This package includes the --no-sandbox flag required for AppImage execution.
EOF

# Create postinst script
cat > "$PKG_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/bash
set -e

# Update desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database -q /usr/share/applications || true
fi

# Update icon cache
if command -v gtk-update-icon-cache &> /dev/null; then
    gtk-update-icon-cache -q -f /usr/share/icons/hicolor || true
fi

exit 0
EOF
chmod +x "$PKG_DIR/DEBIAN/postinst"

# Create postrm script
cat > "$PKG_DIR/DEBIAN/postrm" << 'EOF'
#!/bin/bash
set -e

if [ "$1" = "remove" ]; then
    # Update desktop database
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database -q /usr/share/applications || true
    fi

    # Update icon cache
    if command -v gtk-update-icon-cache &> /dev/null; then
        gtk-update-icon-cache -q -f /usr/share/icons/hicolor || true
    fi
fi

exit 0
EOF
chmod +x "$PKG_DIR/DEBIAN/postrm"

# Build the .deb package
echo -e "${YELLOW}Building .deb package...${NC}"
dpkg-deb --build "$PKG_DIR"

# Move the .deb to the original directory
OUTPUT_DEB="${PKG_NAME}_${VERSION}_amd64.deb"
mv "${PKG_DIR}.deb" ~/"$OUTPUT_DEB"

# Cleanup
cd ~
rm -rf "$WORK_DIR"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Success!${NC}"
echo -e "${GREEN}Package created: ~/$OUTPUT_DEB${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "To install:"
echo "  sudo dpkg -i ~/$OUTPUT_DEB"
echo ""
echo "To uninstall:"
echo "  sudo apt remove saleae-logic2"
