#!/usr/bin/env bash
# Arch Linux Post-Installation Script
# Run this script after first boot as the created user
# Installs AUR helpers, Hyprland, dotfiles (end4 or custom), applications, and performs final configuration

set -euo pipefail

# =====================================================================
# COLOR DEFINITIONS
# =====================================================================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# =====================================================================
# GLOBAL VARIABLES
# =====================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/arch-post-install.log"

# =====================================================================
# UTILITY FUNCTIONS
# =====================================================================
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

# =====================================================================
# LOAD CONFIGURATION
# =====================================================================
load_config() {
    if [[ -f "$SCRIPT_DIR/post-install-env.conf" ]]; then
        source "$SCRIPT_DIR/post-install-env.conf"
    fi
    
    if [[ -f "$SCRIPT_DIR/packages.conf" ]]; then
        source "$SCRIPT_DIR/packages.conf"
    else
        error_exit "packages.conf not found"
    fi

    # Provide sane defaults for backward compatibility
    DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/end4/dotfiles.git}"
    DOTFILES_INSTALL_CMD="${DOTFILES_INSTALL_CMD:-./install.sh}"
}

# =====================================================================
# DOTFILES INSTALLATION (end4 or custom)
# =====================================================================
install_dotfiles() {
    if [[ "${INSTALL_DOTFILES:-yes}" != "yes" ]]; then
        print_info "Skipping dotfiles installation (not enabled)"
        return
    fi

    print_header "DOTFILES INSTALLATION"
    print_info "Cloning dotfiles from ${DOTFILES_REPO}"

    local dotfiles_dir="$HOME/.dotfiles"

    if [[ -d "$dotfiles_dir" ]]; then
        print_warning "Existing $dotfiles_dir detected — moving to ${dotfiles_dir}.bak"
        mv "$dotfiles_dir" "${dotfiles_dir}.bak-$(date +%s)"
    fi

    git clone --depth=1 "${DOTFILES_REPO}" "$dotfiles_dir" || {
        print_error "Failed to clone ${DOTFILES_REPO}"
        return 1
    }

    cd "$dotfiles_dir"
    print_info "Running dotfiles install command: ${DOTFILES_INSTALL_CMD}"

    # Run the install command from the cloned repo
    if [[ -n "${DOTFILES_INSTALL_CMD}" ]]; then
        eval "${DOTFILES_INSTALL_CMD}" || {
            print_error "Dotfiles install command failed"
            return 1
        }
    fi

    print_success "Dotfiles installation complete"
}

# =====================================================================
# MAKEPKG CONFIGURATION
# =====================================================================
configure_makepkg() {
    print_header "MAKEPKG CONFIGURATION"
    
    print_info "Configuring makepkg for parallel compilation..."
    
    # Backup original config
    if [[ -f /etc/makepkg.conf.backup ]]; then
        local timestamp
        timestamp=$(date +%Y%m%d%H%M%S)
        sudo cp /etc/makepkg.conf "/etc/makepkg.conf.backup.${timestamp}"
        print_warning "Existing /etc/makepkg.conf.backup found. Created backup as /etc/makepkg.conf.backup.${timestamp}"
    else
        sudo cp /etc/makepkg.conf /etc/makepkg.conf.backup
        print_success "Backup created: /etc/makepkg.conf.backup"
    fi
    # Set parallel compilation
    local nproc_count
    nproc_count=$(nproc)
    sudo sed -i "s/^#MAKEFLAGS=.*/MAKEFLAGS=\"-j${nproc_count}\"/" /etc/makepkg.conf
    
    print_success "Makepkg configured for ${nproc_count} cores"
}

# =====================================================================
# AUR HELPERS INSTALLATION (yay and paru)
# =====================================================================
install_aur_helpers() {
    print_header "AUR HELPERS INSTALLATION"
    
    print_info "Installing yay and paru AUR helpers..."
    
    # Install dependencies
    print_info "Installing build dependencies..."
    sudo pacman -S --needed --noconfirm base-devel git
    
    local build_dir="/tmp/aur-helpers-build"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    
    # Install yay
    if command -v yay &> /dev/null; then
        print_warning "yay is already installed"
    else
        print_info "Building yay..."
        cd "$build_dir"
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        print_success "yay installed"
    fi
    
    # Install paru
    if command -v paru &> /dev/null; then
        print_warning "paru is already installed"
    else
        print_info "Building paru..."
        cd "$build_dir"
        git clone https://aur.archlinux.org/paru.git
        cd paru
        makepkg -si --noconfirm
        print_success "paru installed"
    fi
    
    cd "$HOME"
    rm -rf "$build_dir"
    
    print_success "AUR helpers installed (yay and paru)"
}

# =====================================================================
# HYPRLAND DESKTOP ENVIRONMENT
# =====================================================================
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

# =====================================================================
# DISPLAY MANAGER
# =====================================================================
install_display_manager() {
    print_header "DISPLAY MANAGER"
    
    print_info "Installing SDDM..."
    sudo pacman -S --needed --noconfirm $DISPLAY_PACKAGES
    
    print_info "Enabling SDDM..."
    sudo systemctl enable sddm
    
    print_success "SDDM installed and enabled"
}

# =====================================================================
# BROWSER INSTALLATION
# =====================================================================
install_browsers() {
    print_header "BROWSER INSTALLATION"
    
    print_info "Installing official browsers..."
    sudo pacman -S --needed --noconfirm $BROWSER_PACKAGES
    
    if command -v yay &> /dev/null; then
        print_info "Installing Brave from AUR..."
        if yay -S --needed --noconfirm brave-bin; then
            print_success "Brave installed"
        else
            print_warning "Failed to install Brave from AUR"
        fi
    else
        print_warning "yay not available, skipping Brave installation"
    fi
    
    print_success "Browser installation complete"
}

# =====================================================================
# PROTONVPN INSTALLATION
# =====================================================================
install_protonvpn() {
    print_header "PROTONVPN INSTALLATION"
    
    if command -v yay &> /dev/null; then
        print_info "Installing ProtonVPN CLI..."
        if yay -S --needed --noconfirm protonvpn-cli; then
            print_success "ProtonVPN CLI installed"
            print_info "Configure with 'protonvpn-cli login' after reboot"
        else
            print_warning "Failed to install ProtonVPN CLI from AUR"
        fi
    else
        print_warning "yay not available, skipping ProtonVPN installation"
    fi
}

# =====================================================================
# TAILSCALE VPN INSTALLATION
# =====================================================================
install_tailscale() {
    print_header "TAILSCALE VPN INSTALLATION"
    
    print_info "Installing Tailscale..."
    sudo pacman -S --needed --noconfirm $VPN_PACKAGES
    
    print_info "Enabling Tailscale service..."
    sudo systemctl enable tailscaled
    
    print_success "Tailscale installed and enabled"
    print_info "Run 'sudo tailscale up' after reboot to authenticate"
}

# =====================================================================
# DOCKER INSTALLATION
# =====================================================================
install_docker() {
    print_header "DOCKER INSTALLATION"
    
    print_info "Installing Docker..."
    sudo pacman -S --needed --noconfirm $DOCKER_PACKAGES
    
    print_info "Enabling Docker service..."
    sudo systemctl enable docker
    
    print_info "Adding user to docker group..."
    sudo usermod -aG docker "$USER"
    
    print_success "Docker installed and configured"
    print_warning "Logout and login again to use docker without sudo"
}

# =====================================================================
# DEVELOPMENT TOOLS
# =====================================================================
install_development_tools() {
    print_header "DEVELOPMENT TOOLS"
    
    print_info "Installing development packages..."
    sudo pacman -S --needed --noconfirm $DEV_PACKAGES
    
    if command -v yay &> /dev/null; then
        print_info "Installing VS Code and Postman from AUR..."
        local aur_failed=0
        
        if ! yay -S --needed --noconfirm visual-studio-code-bin; then
            print_warning "Failed to install VS Code from AUR"
            aur_failed=1
        fi
        
        if ! yay -S --needed --noconfirm postman-bin; then
            print_warning "Failed to install Postman from AUR"
            aur_failed=1
        fi
        
        if [[ $aur_failed -eq 0 ]]; then
            print_success "All AUR development tools installed"
        fi
    else
        print_warning "yay not available, skipping AUR package installation"
    fi
    
    print_success "Development tools installation complete"
}

# =====================================================================
# SYSTEM UTILITIES
# =====================================================================
install_utilities() {
    print_header "SYSTEM UTILITIES"
    
    print_info "Installing system monitoring and utility tools..."
    sudo pacman -S --needed --noconfirm $UTIL_PACKAGES
    
    print_info "Installing hardware utilities..."
    sudo pacman -S --needed --noconfirm $HARDWARE_PACKAGES
    
    print_info "Installing disk utilities..."
    sudo pacman -S --needed --noconfirm $DISK_PACKAGES
    
    print_info "Installing compression tools..."
    sudo pacman -S --needed --noconfirm $COMPRESSION_PACKAGES
    
    print_success "System utilities installed"
}

# =====================================================================
# FIREWALL CONFIGURATION
# =====================================================================
configure_firewall() {
    if [[ "${ENABLE_FIREWALL:-no}" != "yes" ]]; then
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
    sudo ufw --force enable
    
    print_success "Firewall configured and enabled"
}

# =====================================================================
# SSH CONFIGURATION
# =====================================================================
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

# =====================================================================
# SYSTEM OPTIMIZATION
# =====================================================================
configure_sysctl() {
    print_header "SYSTEM OPTIMIZATION"
    
    print_info "Configuring sysctl tweaks..."
    
    sudo tee /etc/sysctl.d/99-custom.conf > /dev/null <<EOF
# System optimization tweaks
# Reduce swap usage
vm.swappiness=10
vm.vfs_cache_pressure=50
# Increase inotify watches for development
fs.inotify.max_user_watches=524288
EOF
    
    sudo sysctl --system
    
    print_success "System optimization applied"
}

# =====================================================================
# FINAL CONFIGURATION
# =====================================================================
final_configuration() {
    print_header "FINAL CONFIGURATION"
    
    # Update system
    print_info "Updating system packages..."
    sudo pacman -Syu --noconfirm
    
    # Clean package cache
    print_info "Cleaning package cache..."
    sudo pacman -Sc --noconfirm || true
    yay -Sc --noconfirm || true
    
    print_success "Final configuration complete"
}

# =====================================================================
# INSTALLATION SUMMARY
# =====================================================================
print_summary() {
    print_header "INSTALLATION SUMMARY"
    
    echo "Installed Components:"
    echo "  ✓ AUR Helpers: yay, paru"
    echo "  ✓ Desktop Environment: Hyprland"
    [[ "${INSTALL_DOTFILES:-no}" == "yes" ]] && echo "  ✓ Dotfiles: Installed from ${DOTFILES_REPO}"
    echo "  ✓ Display Manager: SDDM"
    echo "  ✓ Browsers: Firefox, Chromium, Brave"
    echo "  ✓ VPN: ProtonVPN CLI"
    echo "  ✓ VPN: Tailscale (mesh VPN for remote access)"
    echo "  ✓ Docker: docker, docker-compose"
    echo "  ✓ Development: VS Code, Node.js, Python, Postman"
    echo "  ✓ Utilities: btop, htop, glances, fastfetch"
    [[ "${ENABLE_FIREWALL:-no}" == "yes" ]] && echo "  ✓ Firewall: UFW (enabled)"
    echo
    
    print_info "Next Steps:"
    echo "1. Reboot the system: sudo reboot"
    echo "2. SDDM will start automatically"
    echo "3. Login and select Hyprland as your session"
    echo "4. Docker: logout/login to use without sudo"
    echo "5. ProtonVPN: Configure with 'protonvpn-cli login'"
    echo "6. Tailscale: Connect with 'sudo tailscale up'"
    echo
}

# =====================================================================
# MAIN
# =====================================================================
main() {
    # Initialize log
    echo "=== Arch Linux Post-Installation Script ===" > "$LOG_FILE"
    echo "Started: $(date)" >> "$LOG_FILE"
    
    print_header "ARCH LINUX POST-INSTALLATION"
    print_info "Log file: $LOG_FILE"
    echo
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        error_exit "This script must NOT be run as root. Run as your user account."
    fi
    
    check_internet
    load_config
    
    configure_makepkg || true
    install_aur_helpers || true
    install_hyprland || true
    install_display_manager || true
    install_dotfiles || true
    install_browsers || true
    install_protonvpn || true
    install_tailscale || true
    install_docker || true
    install_development_tools || true
    install_utilities || true
    configure_firewall || true
    configure_ssh || true
    configure_sysctl || true
    final_configuration || true
    
    print_summary
    
    print_success "Post-installation complete!"
    
    read -rp "Reboot now? (yes/no): " reboot
    if [[ "$reboot" == "yes" ]]; then
        sudo reboot
    fi
}

main "$@"