#!/usr/bin/env bash
# Arch Linux Chroot Configuration Script
# Executed inside arch-chroot during installation
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
readonly NC='\033[0m'

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

error_exit() {
    print_error "$1"
    exit 1
}

# ==============================================================================
# LOAD ENVIRONMENT
# ==============================================================================

if [[ ! -f /root/chroot-env.conf ]]; then
    error_exit "Environment configuration file not found"
fi

source /root/chroot-env.conf
source /root/packages.conf

# ==============================================================================
# TIMEZONE AND LOCALIZATION
# ==============================================================================

configure_timezone() {
    print_info "Setting timezone to $TIMEZONE..."
    ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
    hwclock --systohc
    print_success "Timezone configured"
}

configure_locale() {
    print_info "Configuring locale..."
    
    # Enable locale in /etc/locale.gen
    sed -i "s/^#${LOCALE}/${LOCALE}/" /etc/locale.gen
    
    # Also enable en_US.UTF-8 if different locale was chosen
    if [[ "$LOCALE" != "en_US.UTF-8" ]]; then
        sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
    fi
    
    locale-gen
    
    echo "LANG=$LOCALE" > /etc/locale.conf
    echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
    
    print_success "Locale configured"
}

# ==============================================================================
# NETWORK CONFIGURATION
# ==============================================================================

configure_network() {
    print_info "Configuring network..."
    
    echo "$HOSTNAME" > /etc/hostname
    
    cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF
    
    print_success "Network configured"
}

# ==============================================================================
# BOOTLOADER INSTALLATION (systemd-boot)
# ==============================================================================

install_bootloader() {
    print_info "Installing systemd-boot bootloader..."
    
    # Install systemd-boot
    bootctl install
    
    # Create loader configuration
    cat > /boot/loader/loader.conf <<EOF
default arch.conf
timeout 3
console-mode max
editor no
EOF
    
    # Determine partition naming scheme
    local root_partition
    if [[ "$DISK" == *"nvme"* ]]; then
        root_partition="${DISK}p2"
    else
        root_partition="${DISK}2"
    fi
    
    # Get root partition UUID
    local root_uuid
    root_uuid=$(blkid -s UUID -o value "$root_partition")
    
    # Create boot entry
    cat > /boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=UUID=${root_uuid} rw quiet splash
EOF
    
    print_success "Bootloader installed"
}

# ==============================================================================
# INITRAMFS CONFIGURATION
# ==============================================================================

configure_mkinitcpio() {
    print_info "Configuring initramfs..."
    
    # Backup original config
    cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.backup
    
    # Add Intel graphics module for better hardware compatibility
    sed -i 's/^MODULES=()/MODULES=(i915)/' /etc/mkinitcpio.conf
    
    # Regenerate initramfs
    mkinitcpio -P
    
    print_success "Initramfs configured"
}

# ==============================================================================
# USER MANAGEMENT
# ==============================================================================

set_root_password() {
    print_info "Setting root password..."
    echo "root:$ROOT_PASSWORD" | chpasswd
    print_success "Root password set"
}

create_user() {
    print_info "Creating user: $USERNAME..."
    
    useradd -m -G wheel,audio,video,optical,storage -s /bin/bash "$USERNAME"
    echo "${USERNAME}:${USER_PASSWORD}" | chpasswd
    
    print_success "User created"
}

configure_sudo() {
    print_info "Configuring sudo..."
    
    # Enable wheel group for sudo
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
    
    # Set EDITOR for visudo
    echo 'Defaults editor=/usr/bin/vim' >> /etc/sudoers.d/editor
    chmod 0440 /etc/sudoers.d/editor
    
    print_success "Sudo configured"
}

# ==============================================================================
# PACMAN CONFIGURATION
# ==============================================================================

configure_pacman() {
    print_info "Configuring Pacman..."
    
    # Enable parallel downloads
    sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
    
    # Enable color output
    sed -i 's/^#Color/Color/' /etc/pacman.conf
    
    # Enable VerbosePkgLists
    sed -i 's/^#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
    
    # Enable multilib repository (for 32-bit support)
    sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf
    
    print_success "Pacman configured"
}

# ==============================================================================
# ESSENTIAL SERVICES
# ==============================================================================

enable_services() {
    print_info "Enabling essential services..."
    
    systemctl enable NetworkManager
    systemctl enable systemd-timesyncd
    
    print_success "Services enabled"
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    echo -e "${CYAN}"
    echo "========================================================================"
    echo "  CHROOT CONFIGURATION"
    echo "========================================================================"
    echo -e "${NC}"
    
    configure_timezone
    configure_locale
    configure_network
    configure_pacman
    install_bootloader
    configure_mkinitcpio
    set_root_password
    create_user
    configure_sudo
    enable_services
    
    echo
    print_success "Chroot configuration complete!"
    echo
}

main "$@"
