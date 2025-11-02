# saleae-logic2-appimage-to-deb

Convert Saleae Logic 2 AppImage to a proper .deb package for Ubuntu/Debian systems.

## Overview

This script downloads the latest Saleae Logic 2 AppImage and creates a .deb package with proper system integration including:

- Desktop menu entry
- Proper application icon (extracted from Windows installer)
- Correct taskbar icon matching
- Built-in `--no-sandbox` flag (required for AppImage execution)
- System-wide installation

## Features

- ✅ Automatically downloads the latest Logic 2 version
- ✅ Extracts official icon from Windows installer
- ✅ Creates proper .deb package structure
- ✅ Includes post-install scripts for icon/desktop cache updates
- ✅ Fixes AppImage taskbar icon issue with correct `StartupWMClass`
- ✅ No more manual `--no-sandbox` flags needed

## Requirements

```bash
sudo apt install curl wget icoutils dpkg-dev imagemagick
```

## Usage

```bash
./build-logic2-deb.sh
```

This will:
1. Download the latest Logic 2 AppImage for Linux
2. Download the Windows installer to extract the official icon
3. Create a .deb package in your home directory

## Installation

After running the build script:

```bash
sudo dpkg -i ~/saleae-logic2_[VERSION]_amd64.deb
```

Then launch Logic 2 from your application menu or run:

```bash
saleae-logic2
```

## Uninstallation

```bash
sudo apt remove saleae-logic2
```

## Package Details

- **Install location**: `/usr/lib/saleae-logic2/`
- **Binary wrapper**: `/usr/bin/saleae-logic2`
- **Desktop entry**: `/usr/share/applications/Logic.desktop`
- **Icon**: `/usr/share/icons/hicolor/256x256/apps/saleae-logic2.png`

## Why This Script?

Saleae provides Logic 2 as an AppImage, which works but has some integration issues on Ubuntu:

1. AppImages require the `--no-sandbox` flag to run
2. The taskbar icon appears as a generic gear icon
3. No desktop menu integration by default
4. Manual management of updates

This script solves all these issues by creating a proper .deb package with full system integration.

## License

This is a packaging script. Saleae Logic 2 itself is proprietary software owned by Saleae LLC.
See https://www.saleae.com for official software and licensing terms.

## Credits

Script created to solve AppImage integration issues on Ubuntu 24.04.
