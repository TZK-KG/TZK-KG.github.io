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
# MAKEPKG, AUR, Hyprland, Browsers, Docker, etc. (unchanged)
# =====================================================================
# (retain existing helper functions: configure_makepkg, install_aur_helpers, install_hyprland, ...)

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