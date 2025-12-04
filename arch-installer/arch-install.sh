#!/usr/bin/env bash
# Arch Linux Installation Script for Dell OptiPlex 3040 MT
# Target: UEFI systems with automated deployment
# References: https://wiki.archlinux.org/title/Installation_guide

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
INSTALL_HYDE="yes"
AUTOMATION_MODE="interactive"

# Partition variables
EFI_SIZE="512MiB"
ROOT_SIZE="100GiB"
HOME_SIZE="200GiB"
SWAP_SIZE="8GiB"
# DATA partition gets remaining space

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
INSTALL_HYDE="$INSTALL_HYDE"
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
        
        read -rp "Install HyDE dotfiles? (yes/no) [default: yes]: " hyde
        INSTALL_HYDE="${hyde:-yes}"
        
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
    echo "Install HyDE: $INSTALL_HYDE"
    echo "Enable Firewall: $ENABLE_FIREWALL"
    echo
    
    read -rp "Proceed with installation? (yes/no): " proceed
    [[ "$proceed" != "yes" ]] && error_exit "Installation cancelled by user"
    
    save_checkpoint "USER_INPUT_COMPLETE"
}

# ==============================================================================
# DISK SETUP
# ==============================================================================

disk_setup() {
    print_header "DISK PARTITIONING"
    
    print_info "Partitioning $DISK..."
#!/bin/bash
# Arch Linux Installation Script for 256GB USB Drive
# Target: Portable USB installation optimized for USB longevity
# Compatible with Dell OptiPlex 3040 MT and any UEFI system

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Partition sizes for 256GB USB drive
EFI_SIZE="512MiB"
ROOT_SIZE="60GiB"
HOME_SIZE="80GiB"
SWAP_SIZE="8GiB"
DATA_SIZE="100%"  # Remaining space (~105GB)

# Minimum disk size (in GB)
MIN_DISK_SIZE=200
RECOMMENDED_DISK_SIZE=256

# Default values
DISK=""
HOSTNAME="archlinux-usb"
USERNAME=""
TIMEZONE="UTC"
LOCALE="en_US.UTF-8"
KEYMAP="us"

# Configuration file
CONFIG_FILE="config.conf"

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
    echo ""
}

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        print_info "Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE"
    fi
}

check_requirements() {
    print_header "Checking System Requirements"
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
    
    # Check if running in UEFI mode
    if [[ ! -d /sys/firmware/efi ]]; then
        print_error "System is not booted in UEFI mode"
        exit 1
    fi
    
    # Check internet connection
    if ! ping -c 1 archlinux.org &> /dev/null; then
        print_warning "No internet connection detected"
        print_warning "Please ensure you have network connectivity before proceeding"
    fi
    
    print_info "All requirements met"
}

select_disk() {
    print_header "Disk Selection"
    
    echo "Available disks:"
    lsblk -d -o NAME,SIZE,TYPE,MODEL | grep disk
    echo ""
    
    if [[ -z "$DISK" ]]; then
        read -p "Enter the disk to install on (e.g., /dev/sdb): " DISK
    fi
    
    if [[ ! -b "$DISK" ]]; then
        print_error "Invalid disk: $DISK"
        exit 1
    fi
    
    # Get disk size in GB
    DISK_SIZE=$(lsblk -d -n -o SIZE -b "$DISK" | awk '{print int($1/1024/1024/1024)}')
    
    print_info "Selected disk: $DISK (${DISK_SIZE}GB)"
    
    # Validate disk size
    if [[ $DISK_SIZE -lt $MIN_DISK_SIZE ]]; then
        print_error "Disk size (${DISK_SIZE}GB) is smaller than minimum required (${MIN_DISK_SIZE}GB)"
        exit 1
    elif [[ $DISK_SIZE -lt $RECOMMENDED_DISK_SIZE ]]; then
        print_warning "Disk size (${DISK_SIZE}GB) is smaller than recommended (${RECOMMENDED_DISK_SIZE}GB)"
        print_warning "You may run out of space on the /data partition"
        read -p "Do you want to continue? (yes/no): " CONTINUE
        if [[ "$CONTINUE" != "yes" ]]; then
            exit 1
        fi
    fi
    
    # Final confirmation
    echo ""
    print_warning "WARNING: All data on $DISK will be erased!"
    read -p "Type 'YES' to continue: " CONFIRM
    if [[ "$CONFIRM" != "YES" ]]; then
        print_info "Installation cancelled"
        exit 0
    fi
}

disk_setup() {
    print_header "Setting Up Disk Partitions"
    
    # Unmount any mounted partitions
    umount -R /mnt 2>/dev/null || true
    
    # Wipe disk
    print_info "Wiping disk..."
    wipefs -af "$DISK"
    sgdisk -Z "$DISK"
    
    # Create GPT partition table and partitions
    print_info "Creating partitions..."
    parted -s "$DISK" mklabel gpt
    parted -s "$DISK" mkpart ESP fat32 1MiB "$EFI_SIZE"
    parted -s "$DISK" set 1 esp on
    parted -s "$DISK" mkpart primary ext4 "$EFI_SIZE" "$((512 + 100 * 1024))MiB"
    parted -s "$DISK" mkpart primary ext4 "$((512 + 100 * 1024))MiB" "$((512 + 100 * 1024 + 200 * 1024))MiB"
    parted -s "$DISK" mkpart primary linux-swap "$((512 + 100 * 1024 + 200 * 1024))MiB" "$((512 + 100 * 1024 + 200 * 1024 + 8 * 1024))MiB"
    parted -s "$DISK" mkpart primary ext4 "$((512 + 100 * 1024 + 200 * 1024 + 8 * 1024))MiB" 100%
    
    # Wait for partitions to be recognized
    # Wipe existing partition table
    print_info "Wiping existing partition table..."
    wipefs -af "$DISK"
    sgdisk --zap-all "$DISK"
    
    # Create GPT partition table and partitions
    print_info "Creating new partition table..."
    parted -s "$DISK" mklabel gpt
    
    print_info "Creating EFI partition (512MB)..."
    parted -s "$DISK" mkpart "EFI" fat32 1MiB 513MiB
    parted -s "$DISK" set 1 esp on
    
    print_info "Creating ROOT partition (60GB)..."
    parted -s "$DISK" mkpart "ROOT" ext4 513MiB 60.5GiB
    
    print_info "Creating HOME partition (80GB)..."
    parted -s "$DISK" mkpart "HOME" ext4 60.5GiB 140.5GiB
    
    print_info "Creating SWAP partition (8GB)..."
    parted -s "$DISK" mkpart "SWAP" linux-swap 140.5GiB 148.5GiB
    
    print_info "Creating DATA partition (remaining ~105GB)..."
    parted -s "$DISK" mkpart "DATA" ext4 148.5GiB 100%
    
    # Wait for partition table to be re-read
    sleep 2
    partprobe "$DISK"
    sleep 2
    
    # Determine partition naming scheme (sda1 vs nvme0n1p1)
    local part_prefix=""
    if [[ "$DISK" == *"nvme"* ]]; then
        part_prefix="${DISK}p"
    else
        part_prefix="${DISK}"
    # Determine partition naming scheme
    if [[ "$DISK" =~ "nvme" ]] || [[ "$DISK" =~ "mmcblk" ]]; then
        PART_PREFIX="${DISK}p"
    else
        PART_PREFIX="${DISK}"
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
    
    # Generate fstab
    print_info "Generating fstab..."
    genfstab -U /mnt >> /mnt/etc/fstab
    
    print_success "fstab generated"
    
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
INSTALL_HYDE="$INSTALL_HYDE"
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

# ==============================================================================
# MAIN
# ==============================================================================

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
    
    print_info "Formatting EFI partition..."
    mkfs.fat -F32 "${PART_PREFIX}1"
    
    print_info "Formatting ROOT partition..."
    mkfs.ext4 -F "${PART_PREFIX}2"
    
    print_info "Formatting HOME partition..."
    mkfs.ext4 -F "${PART_PREFIX}3"
    
    print_info "Setting up SWAP partition..."
    mkswap "${PART_PREFIX}4"
    
    print_info "Formatting DATA partition..."
    mkfs.ext4 -F "${PART_PREFIX}5"
    
    # Mount partitions
    print_info "Mounting partitions..."
    mount "${PART_PREFIX}2" /mnt
    
    mkdir -p /mnt/boot/efi
    mount "${PART_PREFIX}1" /mnt/boot/efi
    
    mkdir -p /mnt/home
    mount "${PART_PREFIX}3" /mnt/home
    
    mkdir -p /mnt/data
    mount "${PART_PREFIX}5" /mnt/data
    
    swapon "${PART_PREFIX}4"
    
    print_info "Disk setup complete"
    echo ""
    lsblk "$DISK"
}

install_base() {
    print_header "Installing Base System"
    
    # Update mirrorlist
    print_info "Updating mirrorlist..."
    reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
    
    # Install base system
    print_info "Installing base packages (this may take a while)..."
    pacstrap /mnt base linux linux-firmware
    
    # Generate fstab with noatime for USB longevity
    print_info "Generating fstab..."
    genfstab -U /mnt >> /mnt/etc/fstab
    
    # Add noatime to reduce writes on USB
    sed -i 's/relatime/noatime/g' /mnt/etc/fstab
    
    print_info "Base system installed"
}

configure_system() {
    print_header "Configuring System"
    
    # Timezone
    if [[ -z "$TIMEZONE" ]]; then
        read -p "Enter timezone (e.g., America/New_York): " TIMEZONE
    fi
    arch-chroot /mnt ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
    arch-chroot /mnt hwclock --systohc
    print_info "Timezone set to $TIMEZONE"
    
    # Locale
    if [[ -z "$LOCALE" ]]; then
        read -p "Enter locale (default: en_US.UTF-8): " LOCALE
        LOCALE=${LOCALE:-en_US.UTF-8}
    fi
    echo "$LOCALE UTF-8" >> /mnt/etc/locale.gen
    arch-chroot /mnt locale-gen
    echo "LANG=$LOCALE" > /mnt/etc/locale.conf
    print_info "Locale set to $LOCALE"
    
    # Keymap
    if [[ -z "$KEYMAP" ]]; then
        read -p "Enter keymap (default: us): " KEYMAP
        KEYMAP=${KEYMAP:-us}
    fi
    echo "KEYMAP=$KEYMAP" > /mnt/etc/vconsole.conf
    print_info "Keymap set to $KEYMAP"
    
    # Hostname
    if [[ -z "$HOSTNAME" ]]; then
        read -p "Enter hostname (default: archlinux-usb): " HOSTNAME
        HOSTNAME=${HOSTNAME:-archlinux-usb}
    fi
    echo "$HOSTNAME" > /mnt/etc/hostname
    
    # Hosts file
    cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF
    print_info "Hostname set to $HOSTNAME"
    
    # Root password
    print_info "Setting root password..."
    arch-chroot /mnt passwd
    
    # Create user
    if [[ -z "$USERNAME" ]]; then
        read -p "Enter username: " USERNAME
    fi
    arch-chroot /mnt useradd -m -G wheel,audio,video,storage -s /bin/bash "$USERNAME"
    print_info "Setting password for $USERNAME..."
    arch-chroot /mnt passwd "$USERNAME"
    
    # Enable sudo for wheel group
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers
    
    print_info "System configuration complete"
}

install_bootloader() {
    print_header "Installing Bootloader"
    
    # Install GRUB and efibootmgr
    print_info "Installing GRUB..."
    arch-chroot /mnt pacman -S --noconfirm grub efibootmgr
    
    # Install GRUB to EFI partition
    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ARCH --removable
    
    # Configure GRUB for USB optimization
    # Note: Modern kernels (5.0+) automatically select appropriate I/O schedulers
    # The 'elevator' parameter is deprecated but kept for compatibility with older kernels
    
    # Generate GRUB configuration
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    
    print_info "Bootloader installed"
}

install_packages() {
    print_header "Installing Additional Packages"
    
    if [[ -f "packages.conf" ]]; then
        print_info "Installing packages from packages.conf..."
        PACKAGES=$(grep -v '^#' packages.conf | grep -v '^$' | tr '\n' ' ')
        arch-chroot /mnt pacman -S --noconfirm $PACKAGES
    else
        print_info "No packages.conf found, installing essential packages..."
        arch-chroot /mnt pacman -S --noconfirm networkmanager sudo vim git
    fi
    
    # Enable NetworkManager
    arch-chroot /mnt systemctl enable NetworkManager
    
    print_info "Package installation complete"
}

finalize() {
    print_header "Finalizing Installation"
    
    # Unmount all partitions
    print_info "Unmounting partitions..."
    swapoff -a
    umount -R /mnt
    
    print_info "Installation complete!"
    echo ""
    print_info "You can now reboot your system"
    print_info "Remember to remove the installation media and boot from the USB drive"
    echo ""
    print_warning "USB Drive Optimization Notes:"
    print_warning "- noatime mount option has been enabled to reduce writes"
    print_warning "- Modern kernel will auto-select optimal I/O scheduler for USB"
    print_warning "- Consider enabling zram for swap to reduce USB wear"
    echo ""
}

main() {
    print_header "Arch Linux USB Installation Script"
    print_info "Target: 256GB USB Drive (portable installation)"
    echo ""
    
    load_config
    check_requirements
    select_disk
    disk_setup
    install_base
    configure_system
    install_bootloader
    install_packages
    finalize
}

# Run main function
main
