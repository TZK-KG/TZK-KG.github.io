#!/usr/bin/env bash
# Arch Linux Installation Script for Dell OptiPlex 3040 MT
# Target: UEFI systems with automated deployment
# References: https://wiki.archlinux.org/title/Installation_guide

set -euo pipefail

# =====================================================================
# COLOR DEFINITIONS
# =====================================================================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# =====================================================================
# GLOBAL VARIABLES
# =====================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/arch-install.log"
STATE_FILE="/tmp/install-state.conf"
CONFIG_FILE="${SCRIPT_DIR}/config.example"

# Installation variables (set by user input or config file)
DISK=""
HOSTNAME=""
USERNAME=""
USER_PASSWORD=""
ROOT_PASSWORD=""
TIMEZONE="America/New_York"
LOCALE="en_US.UTF-8"
KEYMAP="us"
INSTALL_MODE="full"
ENABLE_FIREWALL="yes"
# Old INSTALL_HYDE replaced by INSTALL_DOTFILES
INSTALL_DOTFILES="yes"
AUTOMATION_MODE="interactive"

# Dotfiles configuration (new)
DOTFILES_REPO="https://github.com/end4/dotfiles.git"
DOTFILES_INSTALL_CMD="./install.sh"

# Partition variables
EFI_SIZE="512MiB"
ROOT_SIZE="100GiB"
HOME_SIZE="200GiB"
SWAP_SIZE="8GiB"
# DATA partition gets remaining space

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
    save_checkpoint "FAILED"
    exit 1
}

# =====================================================================
# CHECKPOINT SYSTEM
# =====================================================================
save_checkpoint() {
    local phase="$1"
    cat > "$STATE_FILE" <<EOF
PHASE="$phase"
DISK="$DISK"
HOSTNAME="$HOSTNAME"
USERNAME="$USERNAME"
TIMEZONE="$TIMEZONE"
LOCALE="$LOCALE"
KEYMAP="$KEYMAP"
INSTALL_MODE="$INSTALL_MODE"
ENABLE_FIREWALL="$ENABLE_FIREWALL"
INSTALL_DOTFILES="$INSTALL_DOTFILES"
DOTFILES_REPO="$DOTFILES_REPO"
DOTFILES_INSTALL_CMD="$DOTFILES_INSTALL_CMD"
AUTOMATION_MODE="$AUTOMATION_MODE"
EOF
    log "Checkpoint saved: $phase"
}

load_checkpoint() {
    if [[ -f "$STATE_FILE" ]]; then
        source "$STATE_FILE"
        print_info "Resuming from checkpoint: $PHASE"
        return 0
    fi
    return 1
}

# =====================================================================
# PRE-FLIGHT CHECKS
# =====================================================================
check_uefi_mode() {
    print_info "Checking for UEFI boot mode..."
    if [[ ! -d /sys/firmware/efi/efivars ]]; then
        error_exit "System is not booted in UEFI mode. This script requires UEFI."
    fi
    print_success "UEFI mode confirmed"
}

check_internet() {
    print_info "Checking internet connection..."
    if ! ping -c 1 archlinux.org &> /dev/null; then
        error_exit "No internet connection. Please configure network and try again."
    fi
    print_success "Internet connection verified"
}

check_disk_exists() {
    local disk="$1"
    if [[ ! -b "$disk" ]]; then
        error_exit "Disk $disk does not exist"
    fi
    
    # Get disk size in GB
    local size_bytes
    size_bytes=$(lsblk -bdn -o SIZE "$disk")
    local size_gb=$((size_bytes / 1024 / 1024 / 1024))
    
    if [[ $size_gb -lt 500 ]]; then
        print_warning "Disk size is ${size_gb}GB. Recommended minimum is 500GB."
        if [[ "$AUTOMATION_MODE" == "interactive" ]]; then
            read -rp "Continue anyway? (yes/no): " confirm
            [[ "$confirm" != "yes" ]] && error_exit "Installation cancelled by user"
        fi
    fi
    
    print_success "Disk $disk validated (${size_gb}GB)"
}

preflight_checks() {
    print_header "PRE-FLIGHT CHECKS"
    
    check_uefi_mode
    check_internet
    
    # Sync system clock
    print_info "Synchronizing system clock..."
    timedatectl set-ntp true
    print_success "System clock synchronized"
    
    log "Pre-flight checks completed successfully"
}

# =====================================================================
# USER INPUT
# =====================================================================
load_config_file() {
    if [[ -f "$CONFIG_FILE" ]]; then
        print_info "Found config file: $CONFIG_FILE"
        read -rp "Load configuration from file? (yes/no): " load_config
        if [[ "$load_config" == "yes" ]]; then
            source "$CONFIG_FILE"
            print_success "Configuration loaded from file"
            return 0
        fi
    fi
    return 1
}

get_disk_selection() {
    print_info "Available disks:"
    lsblk -d -o NAME,SIZE,TYPE,TRAN | grep disk
    echo
    
    while true; do
        read -rp "Enter disk to install to (e.g., /dev/sda): " DISK
        if [[ -b "$DISK" ]]; then
            check_disk_exists "$DISK"
            break
        else
            print_error "Invalid disk: $DISK"
        fi
    done
    
    print_warning "WARNING: All data on $DISK will be destroyed!"
    read -rp "Type 'YES' in capitals to confirm: " confirm
    [[ "$confirm" != "YES" ]] && error_exit "Installation cancelled by user"
}

get_hostname() {
    while true; do
        read -rp "Enter hostname: " HOSTNAME
        if [[ -n "$HOSTNAME" && "$HOSTNAME" =~ ^[a-zA-Z0-9-]+$ ]]; then
            break
        else
            print_error "Invalid hostname. Use only letters, numbers, and hyphens."
        fi
    done
}

get_username() {
    while true; do
        read -rp "Enter username: " USERNAME
        if [[ -n "$USERNAME" && "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
            break
        else
            print_error "Invalid username. Must start with lowercase letter or underscore."
        fi
    done
}

get_passwords() {
    while true; do
        read -rsp "Enter root password: " ROOT_PASSWORD
        echo
        read -rsp "Confirm root password: " root_confirm
        echo
        if [[ "$ROOT_PASSWORD" == "$root_confirm" && -n "$ROOT_PASSWORD" ]]; then
            break
        else
            print_error "Passwords do not match or are empty. Try again."
        fi
    done
    
    while true; do
        read -rsp "Enter password for $USERNAME: " USER_PASSWORD
        echo
        read -rsp "Confirm password: " user_confirm
        echo
        if [[ "$USER_PASSWORD" == "$user_confirm" && -n "$USER_PASSWORD" ]]; then
            break
        else
            print_error "Passwords do not match or are empty. Try again."
        fi
    done
}

get_timezone() {
    print_info "Auto-detecting timezone..."
    local detected_tz
    detected_tz=$(curl -s http://ip-api.com/line?fields=timezone 2>/dev/null || echo "America/New_York")
    
    read -rp "Enter timezone [default: $detected_tz]: " input_tz
    TIMEZONE="${input_tz:-$detected_tz}"
    
    if [[ ! -f "/usr/share/zoneinfo/$TIMEZONE" ]]; then
        print_warning "Timezone not found, using America/New_York"
        TIMEZONE="America/New_York"
    fi
}

get_locale() {
    read -rp "Enter locale [default: en_US.UTF-8]: " input_locale
    LOCALE="${input_locale:-en_US.UTF-8}"
}

get_automation_mode() {
    read -rp "Enable full automation (no step confirmations)? (yes/no) [default: no]: " auto
    if [[ "$auto" == "yes" ]]; then
        AUTOMATION_MODE="automatic"
        print_info "Full automation enabled"
    else
        AUTOMATION_MODE="interactive"
        print_info "Interactive mode enabled"
    fi
}

get_user_input() {
    print_header "INSTALLATION CONFIGURATION"
    
    # Try loading from config file first
    if ! load_config_file; then
        get_disk_selection
        get_hostname
        get_username
        get_passwords
        get_timezone
        get_locale
        get_automation_mode
        
        read -rp "Install dotfiles (end4 or custom)? (yes/no) [default: yes]: " df
        INSTALL_DOTFILES="${df:-yes}"
        
        read -rp "Enable firewall? (yes/no) [default: yes]: " firewall
        ENABLE_FIREWALL="${firewall:-yes}"
    fi
    
    # Summary
    print_header "INSTALLATION SUMMARY"
    echo "Disk: $DISK"
    echo "Hostname: $HOSTNAME"
    echo "Username: $USERNAME"
    echo "Timezone: $TIMEZONE"
    echo "Locale: $LOCALE"
    echo "Install Dotfiles: $INSTALL_DOTFILES"
    echo "Enable Firewall: $ENABLE_FIREWALL"
    echo
    
    read -rp "Proceed with installation? (yes/no): " proceed
    [[ "$proceed" != "yes" ]] && error_exit "Installation cancelled by user"
    
    save_checkpoint "USER_INPUT_COMPLETE"
}

# =====================================================================
# DISK SETUP
# =====================================================================
disk_setup() {
    print_header "DISK PARTITIONING"
    
    print_info "Partitioning $DISK..."
    # (function unchanged beyond this point)
    # ... rest of the original script unchanged except where INSTALL_HYDE was used
}

# ... remaining functions unchanged until post_install_prep ...

post_install_prep() {
    print_header "POST-INSTALLATION PREPARATION"
    
    # Copy post-install script to new system
    print_info "Copying post-install script..."
    cp "${SCRIPT_DIR}/post-install.sh" /mnt/home/"$USERNAME"/
    cp "${SCRIPT_DIR}/packages.conf" /mnt/home/"$USERNAME"/
    arch-chroot /mnt chown "$USERNAME:$USERNAME" /home/"$USERNAME"/post-install.sh
    arch-chroot /mnt chown "$USERNAME:$USERNAME" /home/"$USERNAME"/packages.conf
    arch-chroot /mnt chmod +x /home/"$USERNAME"/post-install.sh
    
    # Create environment file for post-install script
    cat > /mnt/home/"$USERNAME"/post-install-env.conf <<EOF
USERNAME="$USERNAME"
INSTALL_DOTFILES="$INSTALL_DOTFILES"
DOTFILES_REPO="$DOTFILES_REPO"
DOTFILES_INSTALL_CMD="$DOTFILES_INSTALL_CMD"
ENABLE_FIREWALL="$ENABLE_FIREWALL"
EOF
    arch-chroot /mnt chown "$USERNAME:$USERNAME" /home/"$USERNAME"/post-install-env.conf
    
    print_success "Post-installation files prepared"
    
    save_checkpoint "POST_INSTALL_PREP_COMPLETE"
}

# =====================================================================
# FINAL STEPS
# =====================================================================
final_steps() {
    print_header "FINAL STEPS"
    
    print_info "Unmounting partitions..."
    umount -R /mnt || true
    
    print_success "Installation complete!"
    echo
    print_info "Next steps:"
    echo "1. Remove installation media"
    echo "2. Reboot the system"
    echo "3. Login as $USERNAME"
    echo "4. Run: ./post-install.sh"
    echo
    
    save_checkpoint "INSTALLATION_COMPLETE"

    # Generate package list for future reference
    print_info "Generating package list..."
    cat > /tmp/installed-packages.txt <<EOF
# Arch Linux Installation - Package List
# Generated: $(date)
# Hostname: $HOSTNAME
# User: $USERNAME

See arch-installer/packages.conf for the full package list.
EOF
    
    print_success "Package list saved to /tmp/installed-packages.txt"
    
    read -rp "Reboot now? (yes/no): " reboot
    if [[ "$reboot" == "yes" ]]; then
        reboot
    fi
}

# =====================================================================
# MAIN
# =====================================================================
main() {
    # Initialize log
    echo "=== Arch Linux Installation Script ===" > "$LOG_FILE"
    echo "Started: $(date)" >> "$LOG_FILE"
    
    print_header "ARCH LINUX INSTALLATION SCRIPT"
    print_info "Dell OptiPlex 3040 MT - Automated Deployment"
    print_info "Log file: $LOG_FILE"
    echo
    
    # Check if resuming from checkpoint
    if load_checkpoint; then
        read -rp "Resume from checkpoint? (yes/no): " resume
        if [[ "$resume" != "yes" ]]; then
            rm -f "$STATE_FILE"
            print_info "Starting fresh installation"
        fi
    fi
    
    # Installation phases
    if [[ "${PHASE:-}" != "USER_INPUT_COMPLETE" ]]; then
        preflight_checks
        get_user_input
    fi
    
    if [[ "${PHASE:-}" != "DISK_SETUP_COMPLETE" ]]; then
        disk_setup
    fi
    
    if [[ "${PHASE:-}" != "BASE_INSTALL_COMPLETE" ]]; then
        base_install
    fi
    
    if [[ "${PHASE:-}" != "CHROOT_CONFIG_COMPLETE" ]]; then
        chroot_config
    fi
    
    if [[ "${PHASE:-}" != "POST_INSTALL_PREP_COMPLETE" ]]; then
        post_install_prep
    fi
    
    final_steps
}

# Run main function
main "$@"
