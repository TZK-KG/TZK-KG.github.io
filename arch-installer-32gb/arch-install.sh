#!/usr/bin/env bash
# Arch Linux 32GB USB Installation Script
# Lightweight version with end4 dotfiles
# Target: 32GB USB 3.0+ drive with UEFI support
# Optimized for portable usage and minimal footprint

set -euo pipefail

# ==============================================================================
# COLOR DEFINITIONS
# ==============================================================================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# ==============================================================================
# GLOBAL VARIABLES
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/arch-install-32gb.log"
STATE_FILE="/tmp/install-state-32gb.conf"
CONFIG_FILE="${SCRIPT_DIR}/config.example"

# Installation variables (set by user input or config file)
DISK=""
HOSTNAME="arch-32gb-usb"
USERNAME=""
USER_PASSWORD=""
ROOT_PASSWORD=""
TIMEZONE="America/New_York"
LOCALE="en_US.UTF-8"
KEYMAP="us"
INSTALL_MODE="lightweight"
ENABLE_FIREWALL="yes"
INSTALL_END4="yes"
AUTOMATION_MODE="interactive"

# Partition variables for 32GB USB
EFI_SIZE="512MiB"
ROOT_SIZE="15GiB"
HOME_SIZE="10GiB"
SWAP_SIZE="4GiB"
# DATA partition gets remaining space (~2GB)

# Minimum disk size in GB
MIN_DISK_SIZE=30

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
    save_checkpoint "FAILED"
    exit 1
}

# ==============================================================================
# CHECKPOINT SYSTEM
# ==============================================================================

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
INSTALL_END4="$INSTALL_END4"
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

# ==============================================================================
# PRE-FLIGHT CHECKS
# ==============================================================================

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
    
    if [[ $size_gb -lt $MIN_DISK_SIZE ]]; then
        error_exit "Disk size is ${size_gb}GB. Minimum required is ${MIN_DISK_SIZE}GB."
    fi
    
    if [[ $size_gb -lt 32 ]]; then
        print_warning "Disk size is ${size_gb}GB. Recommended minimum is 32GB."
    fi
    
    if [[ $size_gb -gt 64 ]]; then
        print_warning "Disk size is ${size_gb}GB. This installer is optimized for 32GB USB drives."
        print_warning "Consider using the full version installer for larger drives."
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

# ==============================================================================
# USER INPUT
# ==============================================================================

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
        read -rp "Enter disk to install to (e.g., /dev/sdb): " DISK
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
        read -rp "Enter hostname [default: arch-32gb-usb]: " input_hostname
        HOSTNAME="${input_hostname:-arch-32gb-usb}"
        if [[ "$HOSTNAME" =~ ^[a-zA-Z0-9-]+$ ]]; then
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
    detected_tz=$(curl -s https://ip-api.com/line?fields=timezone 2>/dev/null || echo "America/New_York")
    
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
        
        read -rp "Install end4 dotfiles? (yes/no) [default: yes]: " end4
        INSTALL_END4="${end4:-yes}"
        
        read -rp "Enable firewall? (yes/no) [default: yes]: " firewall
        ENABLE_FIREWALL="${firewall:-yes}"
    fi
    
    # Summary
    print_header "INSTALLATION SUMMARY - 32GB LIGHTWEIGHT VERSION"
    echo "Disk: $DISK"
    echo "Hostname: $HOSTNAME"
    echo "Username: $USERNAME"
    echo "Timezone: $TIMEZONE"
    echo "Locale: $LOCALE"
    echo "Install end4 dotfiles: $INSTALL_END4"
    echo "Enable Firewall: $ENABLE_FIREWALL"
    echo
    echo "Partition Layout (32GB USB):"
    echo "  EFI:  $EFI_SIZE"
    echo "  ROOT: $ROOT_SIZE"
    echo "  HOME: $HOME_SIZE"
    echo "  SWAP: $SWAP_SIZE"
    echo "  DATA: Remaining space (~2GB)"
    echo
    
    read -rp "Proceed with installation? (yes/no): " proceed
    [[ "$proceed" != "yes" ]] && error_exit "Installation cancelled by user"
    
    save_checkpoint "USER_INPUT_COMPLETE"
}

# ==============================================================================
# DISK SETUP
# ==============================================================================

disk_setup() {
    print_header "DISK PARTITIONING (32GB USB)"
    
    print_info "Partitioning $DISK..."
    
    # Wipe existing partition table
    print_info "Wiping existing partition table..."
    wipefs -af "$DISK"
    sgdisk --zap-all "$DISK"
    
    # Create GPT partition table
    print_info "Creating new GPT partition table..."
    parted -s "$DISK" mklabel gpt
    
    # Create partitions optimized for 32GB
    print_info "Creating EFI partition (512MB)..."
    parted -s "$DISK" mkpart "EFI" fat32 1MiB 513MiB
    parted -s "$DISK" set 1 esp on
    
    print_info "Creating ROOT partition (15GB)..."
    parted -s "$DISK" mkpart "ROOT" ext4 513MiB 15.5GiB
    
    print_info "Creating HOME partition (10GB)..."
    parted -s "$DISK" mkpart "HOME" ext4 15.5GiB 25.5GiB
    
    print_info "Creating SWAP partition (4GB)..."
    parted -s "$DISK" mkpart "SWAP" linux-swap 25.5GiB 29.5GiB
    
    print_info "Creating DATA partition (remaining ~2GB)..."
    parted -s "$DISK" mkpart "DATA" ext4 29.5GiB 100%
    
    # Wait for partition table to be re-read
    sleep 2
    partprobe "$DISK"
    sleep 2
    
    # Determine partition naming scheme
    local part_prefix=""
    if [[ "$DISK" =~ "nvme" ]] || [[ "$DISK" =~ "mmcblk" ]]; then
        part_prefix="${DISK}p"
    else
        part_prefix="${DISK}"
    fi
    
    # Format partitions
    print_info "Formatting partitions..."
    mkfs.fat -F32 "${part_prefix}1"
    mkfs.ext4 -F "${part_prefix}2"
    mkfs.ext4 -F "${part_prefix}3"
    mkswap "${part_prefix}4"
    mkfs.ext4 -F "${part_prefix}5"
    
    # Mount partitions
    print_info "Mounting partitions..."
    mount "${part_prefix}2" /mnt
    
    mkdir -p /mnt/boot
    mount "${part_prefix}1" /mnt/boot
    
    mkdir -p /mnt/home
    mount "${part_prefix}3" /mnt/home
    
    swapon "${part_prefix}4"
    
    mkdir -p /mnt/data
    mount "${part_prefix}5" /mnt/data
    
    print_success "Disk setup complete"
    lsblk "$DISK"
    
    save_checkpoint "DISK_SETUP_COMPLETE"
}

# ==============================================================================
# BASE SYSTEM INSTALLATION
# ==============================================================================

base_install() {
    print_header "BASE SYSTEM INSTALLATION"
    
    print_info "Installing base system packages..."
    
    # Load package list
    source "${SCRIPT_DIR}/packages.conf"
    
    # Install base system
    pacstrap -K /mnt $BASE_PACKAGES $SYSTEM_PACKAGES
    
    print_success "Base system installed"
    
    # Generate fstab with noatime for USB longevity
    print_info "Generating fstab with USB optimizations..."
    genfstab -U /mnt >> /mnt/etc/fstab
    
    # Add noatime to reduce writes
    sed -i 's/relatime/noatime/g' /mnt/etc/fstab
    
    print_success "fstab generated with noatime"
    
    save_checkpoint "BASE_INSTALL_COMPLETE"
}

# ==============================================================================
# CHROOT CONFIGURATION
# ==============================================================================

chroot_config() {
    print_header "CHROOT CONFIGURATION"
    
    # Copy chroot script to new system
    print_info "Copying chroot script..."
    cp "${SCRIPT_DIR}/chroot-install.sh" /mnt/root/
    cp "${SCRIPT_DIR}/packages.conf" /mnt/root/
    chmod +x /mnt/root/chroot-install.sh
    
    # Create environment file for chroot script
    cat > /mnt/root/chroot-env.conf <<EOF
HOSTNAME="$HOSTNAME"
USERNAME="$USERNAME"
USER_PASSWORD="$USER_PASSWORD"
ROOT_PASSWORD="$ROOT_PASSWORD"
TIMEZONE="$TIMEZONE"
LOCALE="$LOCALE"
KEYMAP="$KEYMAP"
DISK="$DISK"
EOF
    
    # Execute chroot script
    print_info "Executing chroot configuration..."
    arch-chroot /mnt /root/chroot-install.sh
    
    # Cleanup
    rm /mnt/root/chroot-install.sh
    rm /mnt/root/chroot-env.conf
    rm /mnt/root/packages.conf
    
    print_success "Chroot configuration complete"
    
    save_checkpoint "CHROOT_CONFIG_COMPLETE"
}

# ==============================================================================
# POST-INSTALLATION SETUP
# ==============================================================================

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
INSTALL_END4="$INSTALL_END4"
ENABLE_FIREWALL="$ENABLE_FIREWALL"
EOF
    arch-chroot /mnt chown "$USERNAME:$USERNAME" /home/"$USERNAME"/post-install-env.conf
    
    print_success "Post-installation files prepared"
    
    save_checkpoint "POST_INSTALL_PREP_COMPLETE"
}

# ==============================================================================
# FINAL STEPS
# ==============================================================================

final_steps() {
    print_header "FINAL STEPS"
    
    print_info "Unmounting partitions..."
    umount -R /mnt || true
    
    print_success "Installation complete!"
    echo
    print_header "32GB LIGHTWEIGHT ARCH LINUX INSTALLATION"
    echo "Optimized for USB with end4 dotfiles"
    echo
    print_info "Next steps:"
    echo "1. Remove installation media"
    echo "2. Reboot the system"
    echo "3. Login as $USERNAME"
    echo "4. Run: ./post-install.sh"
    echo
    print_info "Lightweight features:"
    echo "  ✓ 32GB USB optimized partitions"
    echo "  ✓ Minimal package selection"
    echo "  ✓ end4 dotfiles (instead of HyDE)"
    echo "  ✓ Single browser (Firefox)"
    echo "  ✓ USB longevity optimizations"
    echo "  ✓ Estimated size: 8-10GB"
    echo
    
    save_checkpoint "INSTALLATION_COMPLETE"
    
    read -rp "Reboot now? (yes/no): " reboot
    if [[ "$reboot" == "yes" ]]; then
        reboot
    fi
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    # Initialize log
    echo "=== Arch Linux 32GB USB Installation Script ===" > "$LOG_FILE"
    echo "Lightweight version with end4 dotfiles" >> "$LOG_FILE"
    echo "Started: $(date)" >> "$LOG_FILE"
    
    print_header "ARCH LINUX 32GB USB INSTALLATION"
    print_info "Lightweight version with end4 dotfiles"
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
