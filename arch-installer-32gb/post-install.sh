#!/usr/bin/env bash
# Arch Linux 32GB USB Post-Installation Script
# Lightweight version with end4 dotfiles
# Run this script after first boot as the created user
# Installs AUR helper, Hyprland, end4 dotfiles, and performs final configuration

set -euo pipefail

# ==============================================================================
# COLOR DEFINITIONS
# ==============================================================================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# ==============================================================================
# GLOBAL VARIABLES
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/arch-post-install-32gb.log"

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

print_header() {
    echo -e "${CYAN}"
    echo "========================================================================"
    echo "  $1"
    echo "========================================================================"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error_exit() {
    print_error "$1"
    log "ERROR: $1"
    exit 1
}

check_internet() {
    print_info "Checking internet connection..."
    if ! ping -c 1 archlinux.org &> /dev/null; then
        error_exit "No internet connection. Please configure network and try again."
    fi
    print_success "Internet connection verified"
}

# ==============================================================================
# LOAD CONFIGURATION
# ==============================================================================

load_config() {
    if [[ -f "$SCRIPT_DIR/post-install-env.conf" ]]; then
        source "$SCRIPT_DIR/post-install-env.conf"
    fi
    
    if [[ -f "$SCRIPT_DIR/packages.conf" ]]; then
        source "$SCRIPT_DIR/packages.conf"
    else
        error_exit "packages.conf not found"
    fi
}

# ==============================================================================
# MAKEPKG CONFIGURATION
# ==============================================================================

configure_makepkg() {
    print_header "MAKEPKG CONFIGURATION"
    
    print_info "Configuring makepkg for parallel compilation..."
    
    # Backup original config
    sudo cp /etc/makepkg.conf /etc/makepkg.conf.backup
    
    # Set parallel compilation
    local nproc_count
    nproc_count=$(nproc)
    sudo sed -i "s/^#MAKEFLAGS=.*/MAKEFLAGS=\"-j${nproc_count}\"/" /etc/makepkg.conf
    
    print_success "Makepkg configured for ${nproc_count} cores"
}

# ==============================================================================
# AUR HELPER INSTALLATION (yay only for lightweight)
# ==============================================================================

install_yay() {
    print_header "AUR HELPER INSTALLATION"
    
    print_info "Installing yay AUR helper..."
    
    if command -v yay &> /dev/null; then
        print_warning "yay is already installed"
        return
    fi
    
    # Install dependencies
    print_info "Installing build dependencies..."
    sudo pacman -S --needed --noconfirm base-devel git
    
    local build_dir="/tmp/yay-build"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    cd "$build_dir"
    
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    
    cd "$HOME"
    rm -rf "$build_dir"
    
    print_success "yay installed"
}

# ==============================================================================
# HYPRLAND DESKTOP ENVIRONMENT
# ==============================================================================

install_hyprland() {
    print_header "HYPRLAND DESKTOP ENVIRONMENT"
    
    print_info "Installing Hyprland and components..."
    sudo pacman -S --needed --noconfirm $HYPRLAND_PACKAGES
    
    print_info "Installing Hyprland extras..."
    sudo pacman -S --needed --noconfirm $HYPRLAND_EXTRAS
    
    print_info "Installing theming packages..."
    sudo pacman -S --needed --noconfirm $THEMING_PACKAGES
    
    print_success "Hyprland installed"
}

install_display_manager() {
    print_header "DISPLAY MANAGER"
    
    print_info "Installing SDDM..."
    sudo pacman -S --needed --noconfirm $DISPLAY_PACKAGES
    
    print_info "Enabling SDDM..."
    sudo systemctl enable sddm
    
    print_success "SDDM installed and enabled"
}

# ==============================================================================
# end4 DOTFILES INSTALLATION
# ==============================================================================

install_end4() {
    if [[ "$INSTALL_END4" != "yes" ]]; then
        print_info "Skipping end4 installation (not enabled)"
        return
    fi
    
    print_header "end4 DOTFILES INSTALLATION"
    
    print_info "Installing dependencies for end4 dotfiles..."
    
    # Install AGS (Aylur's GTK Shell) and other dependencies
    print_info "Installing AGS from AUR..."
    if ! yay -S --needed --noconfirm ags; then
        print_error "Failed to install AGS. end4 dotfiles require AGS to function."
        print_warning "Continuing installation, but end4 may not work properly."
    fi
    
    # Install additional dependencies
    sudo pacman -S --needed --noconfirm \
        gtk3 \
        gtk-layer-shell \
        gnome-bluetooth-3.0 \
        libdbusmenu-gtk3 \
        upower \
        gvfs \
        brightnessctl \
        bluez \
        bluez-utils \
        networkmanager \
        dart-sass \
        fd \
        ripgrep \
        wl-clipboard \
        slurp \
        grim \
        imagemagick \
        pavucontrol \
        playerctl
    
    print_info "Cloning end4 dotfiles from end-4/dots-hyprland..."
    
    local dots_dir="$HOME/dots-hyprland"
    if [[ -d "$dots_dir" ]]; then
        print_warning "end4 directory already exists, removing..."
        rm -rf "$dots_dir"
    fi
    
    # Clone end4 dots-hyprland repository
    git clone --depth 1 https://github.com/end-4/dots-hyprland "$dots_dir"
    
    print_info "Installing end4 dotfiles..."
    cd "$dots_dir"
    
    # Create .config directory if it doesn't exist
    mkdir -p "$HOME/.config"
    
    # Copy configuration files
    print_info "Copying end4 configurations..."
    
    # Copy AGS config
    if [[ -d "ags" ]]; then
        cp -r ags "$HOME/.config/"
        print_success "AGS config installed"
    fi
    
    # Copy Hyprland config
    if [[ -d "hypr" ]]; then
        cp -r hypr "$HOME/.config/"
        print_success "Hyprland config installed"
    fi
    
    # Copy other configs
    for config_dir in waybar kitty rofi gtk-3.0; do
        if [[ -d "$config_dir" ]]; then
            cp -r "$config_dir" "$HOME/.config/"
            print_success "$config_dir config installed"
        fi
    done
    
    # Set executable permissions for scripts
    if [[ -d "$HOME/.config/ags" ]]; then
        find "$HOME/.config/ags" -name "*.sh" -type f -print0 | xargs -0 -r chmod +x 2>/dev/null || true
    fi
    if [[ -d "$HOME/.config/hypr" ]]; then
        find "$HOME/.config/hypr" -name "*.sh" -type f -print0 | xargs -0 -r chmod +x 2>/dev/null || true
    fi
    
    cd "$HOME"
    
    print_success "end4 dotfiles installed"
    print_info "end4 configuration installed at ~/.config/"
}

# ==============================================================================
# BROWSER INSTALLATION (Lightweight)
# ==============================================================================

install_browsers() {
    print_header "BROWSER INSTALLATION"
    
    print_info "Installing Firefox..."
    sudo pacman -S --needed --noconfirm $BROWSER_PACKAGES
    
    print_success "Browser installed (Firefox only for lightweight version)"
}

# ==============================================================================
# SYSTEM UTILITIES (Minimal)
# ==============================================================================

install_utilities() {
    print_header "SYSTEM UTILITIES"
    
    print_info "Installing system monitoring and utility tools..."
    sudo pacman -S --needed --noconfirm $UTIL_PACKAGES
    
    print_success "System utilities installed"
}

# ==============================================================================
# DEVELOPMENT TOOLS (Minimal)
# ==============================================================================

install_development_tools() {
    print_header "DEVELOPMENT TOOLS (Minimal)"
    
    print_info "Installing Python..."
    sudo pacman -S --needed --noconfirm $DEV_PACKAGES
    
    print_success "Development tools installed (Python only)"
}

# ==============================================================================
# TAILSCALE VPN INSTALLATION
# ==============================================================================

install_tailscale() {
    print_header "TAILSCALE VPN INSTALLATION"
    
    print_info "Installing Tailscale..."
    sudo pacman -S --needed --noconfirm $VPN_PACKAGES
    
    print_info "Enabling Tailscale service..."
    sudo systemctl enable tailscaled
    sudo systemctl start tailscaled
    
    print_success "Tailscale installed and enabled"
    print_info "Run 'sudo tailscale up' after reboot to authenticate"
}

# ==============================================================================
# FIREWALL CONFIGURATION
# ==============================================================================

configure_firewall() {
    if [[ "$ENABLE_FIREWALL" != "yes" ]]; then
        print_info "Skipping firewall configuration (not enabled)"
        return
    fi
    
    print_header "FIREWALL CONFIGURATION"
    
    print_info "Installing UFW..."
    sudo pacman -S --needed --noconfirm ufw
    
    print_info "Configuring UFW..."
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    
    print_info "Enabling UFW..."
    sudo systemctl enable ufw
    sudo systemctl start ufw
    sudo ufw enable
    
    print_success "Firewall configured and enabled"
}

# ==============================================================================
# SSH CONFIGURATION
# ==============================================================================

configure_ssh() {
    print_header "SSH CONFIGURATION"
    
    if [[ ! -f /etc/ssh/sshd_config ]]; then
        print_info "Installing OpenSSH..."
        sudo pacman -S --needed --noconfirm openssh
    fi
    
    print_info "Configuring SSH security..."
    
    # Backup original config
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # Disable root login
    sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    
    # Enable key-based authentication
    sudo sed -i 's/^#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    
    print_success "SSH configured (root login disabled)"
}

# ==============================================================================
# SYSTEM OPTIMIZATION FOR 32GB USB
# ==============================================================================

configure_sysctl() {
    print_header "SYSTEM OPTIMIZATION (USB)"
    
    print_info "Configuring sysctl tweaks for USB longevity..."
    
    sudo tee /etc/sysctl.d/99-custom-usb.conf > /dev/null <<EOF
# System optimization tweaks for 32GB USB
# Reduce swap usage to minimize writes
vm.swappiness=10
vm.vfs_cache_pressure=50
# Increase inotify watches for development
fs.inotify.max_user_watches=524288
# Reduce dirty page writeback for USB
vm.dirty_ratio=5
vm.dirty_background_ratio=3
EOF
    
    sudo sysctl --system
    
    print_success "System optimization applied for USB"
}

configure_journal() {
    print_header "JOURNAL OPTIMIZATION (USB)"
    
    print_info "Configuring systemd journal for reduced writes..."
    
    # Limit journal size and use volatile storage
    sudo mkdir -p /etc/systemd/journald.conf.d
    sudo tee /etc/systemd/journald.conf.d/00-journal-size.conf > /dev/null <<EOF
[Journal]
SystemMaxUse=50M
RuntimeMaxUse=50M
SystemMaxFileSize=10M
EOF
    
    print_success "Journal configured for minimal USB writes"
}

# ==============================================================================
# ZRAM SETUP (Optional but recommended)
# ==============================================================================

setup_zram() {
    print_header "ZRAM SETUP (Recommended for USB)"
    
    print_info "Installing zram-generator..."
    sudo pacman -S --needed --noconfirm zram-generator
    
    print_info "Configuring zram..."
    sudo tee /etc/systemd/zram-generator.conf > /dev/null <<EOF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF
    
    print_info "zram will be active after reboot"
    print_success "zram configured (swap in RAM to reduce USB writes)"
}

# ==============================================================================
# FINAL CONFIGURATION
# ==============================================================================

final_configuration() {
    print_header "FINAL CONFIGURATION"
    
    # Update system
    print_info "Updating system packages..."
    sudo pacman -Syu --noconfirm
    
    # Clean package cache
    print_info "Cleaning package cache..."
    sudo pacman -Sc --noconfirm
    yay -Sc --noconfirm
    
    print_success "Final configuration complete"
}

# ==============================================================================
# INSTALLATION SUMMARY
# ==============================================================================

print_summary() {
    print_header "INSTALLATION SUMMARY - 32GB LIGHTWEIGHT VERSION"
    
    echo "Installed Components:"
    echo "  ✓ AUR Helper: yay"
    echo "  ✓ Desktop Environment: Hyprland (lightweight config)"
    [[ "$INSTALL_END4" == "yes" ]] && echo "  ✓ end4 Dotfiles: Installed"
    echo "  ✓ Display Manager: SDDM"
    echo "  ✓ Browser: Firefox (single browser)"
    echo "  ✓ VPN: Tailscale (mesh VPN for remote access)"
    echo "  ✓ Development: Python only"
    echo "  ✓ Utilities: htop, fastfetch (minimal)"
    [[ "$ENABLE_FIREWALL" == "yes" ]] && echo "  ✓ Firewall: UFW (enabled)"
    echo "  ✓ zram: Configured (swap in RAM)"
    echo "  ✓ USB Optimizations: Applied"
    echo
    
    print_info "32GB Lightweight Features:"
    echo "  • Optimized for 32GB USB drives"
    echo "  • end4 dotfiles instead of HyDE"
    echo "  • Minimal package selection"
    echo "  • No Docker, VS Code, or heavy tools"
    echo "  • Single browser (Firefox)"
    echo "  • zram for swap (reduces USB writes)"
    echo "  • Journal and sysctl optimizations"
    echo "  • Estimated size: 8-10GB"
    echo
    
    print_warning "USB Longevity Tips:"
    echo "  • zram is configured (swap in RAM)"
    echo "  • noatime mount option is enabled"
    echo "  • Journal is limited to 50MB"
    echo "  • Minimize large file operations"
    echo "  • Regular backups recommended"
    echo
    
    print_info "Next Steps:"
    echo "1. Reboot the system: sudo reboot"
    echo "2. SDDM will start automatically"
    echo "3. Login and select Hyprland as your session"
    echo "4. Tailscale: Connect with 'sudo tailscale up'"
    echo "5. Enjoy your lightweight Arch Linux with end4!"
    echo
    
    print_info "end4 Dotfiles Info:"
    echo "  • Configuration: ~/.config/ags, ~/.config/hypr"
    echo "  • Repository: https://github.com/end-4/dots-hyprland"
    echo "  • Features: AGS widgets, modern animations, clean interface"
    echo "  • Customization: Edit files in ~/.config/"
    echo
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    # Initialize log
    echo "=== Arch Linux 32GB USB Post-Installation Script ===" > "$LOG_FILE"
    echo "Lightweight version with end4 dotfiles" >> "$LOG_FILE"
    echo "Started: $(date)" >> "$LOG_FILE"
    
    print_header "ARCH LINUX 32GB USB POST-INSTALLATION"
    print_info "Lightweight version with end4 dotfiles"
    print_info "Log file: $LOG_FILE"
    echo
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        error_exit "This script must NOT be run as root. Run as your user account."
    fi
    
    check_internet
    load_config
    
    configure_makepkg
    install_yay
    install_hyprland
    install_display_manager
    install_end4
    install_browsers
    install_development_tools
    install_tailscale
    install_utilities
    configure_firewall
    configure_ssh
    configure_sysctl
    configure_journal
    setup_zram
    final_configuration
    
    print_summary
    
    print_success "Post-installation complete!"
    
    read -rp "Reboot now? (yes/no): " reboot
    if [[ "$reboot" == "yes" ]]; then
        sudo reboot
    fi
}

main "$@"
