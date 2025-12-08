#!/usr/bin/env bash
# Example usage scenarios for the ISO Builder

# ==============================================================================
# EXAMPLE 1: Build a single ISO from local repository with GUI
# ==============================================================================
# This is the simplest way to use the ISO builder
# Simply run the script and follow the interactive prompts

# cd /path/to/TZK-KG.github.io/iso-builder
# ./build-iso.sh
# Then select:
# - Source: Local Files/Directory
# - Browse to: /path/to/TZK-KG.github.io
# - Version: 256GB USB Version
# - Output: ~/my-isos/
# - Name: custom-arch

# ==============================================================================
# EXAMPLE 2: Build from GitHub repository with GUI
# ==============================================================================
# Build an ISO directly from GitHub without cloning first

# cd /path/to/iso-builder
# ./build-iso.sh
# Then select:
# - Source: GitHub Repository URL
# - URL: https://github.com/TZK-KG/TZK-KG.github.io
# - Version: 32GB USB Version
# - Output: ~/isos/
# - Name: arch-portable

# ==============================================================================
# EXAMPLE 3: Automated build with CLI (for CI/CD)
# ==============================================================================
# Build both versions automatically without user interaction

cd "$(dirname "$0")"

# Build from local repository
./build-iso.sh --cli \
    --local .. \
    --version both \
    --output ~/iso-output \
    --name archlinux-$(date +%Y%m%d)

# ==============================================================================
# EXAMPLE 4: Build specific version from GitHub
# ==============================================================================
# Download and build 256GB version from GitHub

# ./build-iso.sh --cli \
#     --github https://github.com/TZK-KG/TZK-KG.github.io \
#     --version 256gb \
#     --output /var/www/html/isos \
#     --name arch-full-latest

# ==============================================================================
# EXAMPLE 5: Quick test build
# ==============================================================================
# Build a single version for testing

# ./build-iso.sh --cli \
#     --local ~/Downloads/TZK-KG.github.io-main \
#     --version 32gb \
#     --output /tmp/test-iso \
#     --name test-build

# ==============================================================================
# EXAMPLE 6: Build with custom names for distribution
# ==============================================================================
# Build both versions with descriptive names

# ./build-iso.sh --cli \
#     --local /path/to/repo \
#     --version both \
#     --output ~/releases/v1.0 \
#     --name archlinux-hyprland-usb

# This will create:
# - archlinux-hyprland-usb-256gb.iso
# - archlinux-hyprland-usb-32gb.iso

# ==============================================================================
# TIPS
# ==============================================================================
# 1. For GUI mode, just run: ./build-iso.sh
# 2. For CLI mode, always include: --cli --source --version --output
# 3. Use --local for faster builds (no network needed)
# 4. Use --github to always get the latest version
# 5. The script requires sudo for mkarchiso
# 6. Build logs are saved in /tmp/iso-builder-*.log
# 7. Check disk space before building (needs ~4GB in /tmp)

echo "This is an examples file. Edit and uncomment the examples you want to run."
