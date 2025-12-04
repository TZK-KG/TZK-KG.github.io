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
    
    # Determine partition naming scheme
    if [[ "$DISK" =~ "nvme" ]] || [[ "$DISK" =~ "mmcblk" ]]; then
        PART_PREFIX="${DISK}p"
    else
        PART_PREFIX="${DISK}"
    fi
    
    # Format partitions
    print_info "Formatting partitions..."
    
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
    pacstrap /mnt base base-devel linux linux-firmware
    
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
    # Add kernel parameters for USB performance
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 elevator=noop"/' /mnt/etc/default/grub
    
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
    print_warning "- Elevator scheduler set to noop for better USB performance"
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
