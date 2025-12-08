#!/usr/bin/env bash
# Custom ISO Hooks
# This script runs during the archiso build process to customize the ISO

set -e

# This script can be used to:
# 1. Add custom packages to the ISO
# 2. Configure system settings
# 3. Add custom files or scripts
# 4. Set up auto-start behaviors

echo "Running custom ISO hooks..."

# Example: Create a welcome message
cat > /etc/motd << 'EOF'
========================================
 Arch Linux Installation ISO
 Custom Build with Installation Scripts
========================================

Installation scripts are located in:
  /root/arch-installer/

To start the installation:
  cd /root/arch-installer
  ./arch-install.sh

For more information, see the README files.

========================================
EOF

# Example: Add custom bashrc additions
cat >> /root/.bashrc << 'EOF'

# Custom additions for installation ISO
if [ -d /root/arch-installer ]; then
    echo ""
    echo "Installation scripts available in /root/arch-installer/"
    echo "Run: cd /root/arch-installer && ./arch-install.sh"
    echo ""
fi
EOF

echo "Custom ISO hooks completed successfully"
