# Arch Linux Installation Scripts

Comprehensive, production-ready Arch Linux installation scripts for automated deployment. Designed specifically for Dell OptiPlex 3040 MT systems but adaptable to most UEFI-based hardware.

## 🎯 Overview

This installation suite provides a complete, automated Arch Linux setup with:
- **Hyprland** - Modern tiling Wayland compositor
- **HyDE** - Beautiful dotfiles from [prasanthrangan/hyprdots](https://github.com/prasanthrangan/hyprdots)
- **Full development environment** - Docker, VS Code, Node.js, Python
- **Security hardened** - UFW firewall, SSH hardening, sudo configuration
- **AUR support** - Both yay and paru pre-installed

## 📋 Features

- ✅ UEFI-only installation with systemd-boot
- ✅ Automated partitioning with intelligent disk layout
- ✅ Checkpoint system for resuming failed installations
- ✅ Colorized output with progress indicators
- ✅ Comprehensive error handling and logging
- ✅ Pre-seeding support for unattended installations
- ✅ Modular package organization
- ✅ Post-installation automation
- ✅ Security best practices

## 🖥️ Target System Specifications

**Designed for Dell OptiPlex 3040 MT:**
- CPU: Intel i7-6700 (6th Gen)
- RAM: 32GB
- Storage: 4TB
- Boot: UEFI only

**Partition Scheme:**
- 512MB EFI System Partition (FAT32)
- 100GB Root partition (ext4)
- 200GB Home partition (ext4)
- 8GB Swap partition
- Remaining space for /data (ext4)

## 🚀 Quick Start

### Prerequisites

1. Boot from Arch Linux installation media (UEFI mode)
2. Verify internet connection:
   ```bash
   ping -c 3 archlinux.org
   ```
3. If using WiFi, connect with `iwctl`:
   ```bash
   iwctl
   station wlan0 scan
   station wlan0 get-networks
   station wlan0 connect "SSID"
   ```

### Installation Steps

1. **Download the scripts:**
   ```bash
   curl -L https://github.com/TZK-KG/TZK-KG.github.io/archive/refs/heads/main.tar.gz | tar xz
   cd TZK-KG.github.io-main/arch-installer
   chmod +x *.sh
   ```

2. **Run the main installation script:**
   ```bash
   ./arch-install.sh
   ```

3. **Follow the prompts:**
   - Select installation disk
   - Set hostname, username, passwords
   - Configure timezone and locale
   - Confirm installation

4. **After reboot, login and run post-installation:**
   ```bash
   ./post-install.sh
   ```

5. **Reboot and enjoy your new Arch Linux system!**

## 📖 Detailed Usage

### Interactive Installation (Default)

The default mode guides you through each step with confirmations:

```bash
./arch-install.sh
```

You'll be prompted for:
- Disk selection (with size verification)
- Hostname
- Username
- Root password
- User password
- Timezone (auto-detected)
- Locale
- Optional components (HyDE, firewall)

### Automated Installation

For unattended installations, use the pre-seeding configuration:

1. **Create configuration:**
   ```bash
   cp config.example my-config.conf
   nano my-config.conf
   ```

2. **Configure your settings:**
   ```bash
   DISK="/dev/sda"
   HOSTNAME="myarch"
   USERNAME="myuser"
   TIMEZONE="America/New_York"
   AUTOMATION_MODE="automatic"
   ```

3. **Run installer:**
   ```bash
   ./arch-install.sh
   ```
   When prompted, load your configuration file.

### Resuming After Failure

If installation fails, the checkpoint system allows resuming:

```bash
./arch-install.sh
# Choose "yes" when asked to resume from checkpoint
```

## 📦 Installed Software

### Base System
- **Kernel:** linux, linux-headers, linux-firmware
- **Essential:** base, base-devel, networkmanager
- **CPU:** intel-ucode (microcode updates)
- **Tools:** git, wget, curl, vim, nano

### Desktop Environment
- **Compositor:** Hyprland (Wayland)
- **Bar:** Waybar
- **Terminal:** Kitty
- **Launcher:** Rofi (Wayland)
- **Notifications:** Mako
- **File Manager:** Thunar
- **Display Manager:** SDDM
- **Dotfiles:** HyDE (optional)

### Browsers
- Firefox (official)
- Chromium (official)
- Brave (AUR)

### Development Tools
- **Editors:** VS Code (AUR)
- **Languages:** Node.js, npm, Python, pip
- **Containers:** Docker, docker-compose, docker-buildx
- **API Testing:** Postman (AUR)

### System Utilities
- **Monitoring:** btop, htop, glances
- **System Info:** fastfetch
- **Documentation:** man-db, man-pages, tldr
- **Hardware:** lm_sensors, smartmontools

### Security & Network
- **VPN:** ProtonVPN CLI (AUR)
- **Firewall:** UFW (optional)
- **SSH:** OpenSSH (hardened configuration)

### AUR Helpers
- **yay** - Yet Another Yogurt
- **paru** - Feature-rich AUR helper

## 🔧 Configuration Files

### arch-install.sh
Main installation script with modular functions:
- Pre-flight checks (UEFI, internet, disk)
- User input collection
- Disk partitioning with parted
- Base system installation
- Chroot configuration execution
- Checkpoint system

### chroot-install.sh
Executed inside arch-chroot:
- Timezone and locale configuration
- Hostname and network setup
- Systemd-boot installation
- User creation with sudo
- Service enablement
- Pacman configuration

### post-install.sh
Run after first boot:
- AUR helpers installation
- Hyprland desktop setup
- HyDE dotfiles installation
- Application installation
- Docker configuration
- Firewall setup
- System optimization

### packages.conf
Organized package lists by category. Easily customizable:
```bash
HYPRLAND_PACKAGES="hyprland waybar kitty rofi-wayland"
BROWSER_PACKAGES="firefox chromium"
DEV_PACKAGES="nodejs npm python python-pip"
```

### config.example
Pre-seeding configuration template for automated installations.

## 🛠️ Customization

### Adding Packages

Edit `packages.conf` to add packages:

```bash
# Add to existing group
UTIL_PACKAGES="$UTIL_PACKAGES neofetch"

# Create new group
CUSTOM_PACKAGES="package1 package2 package3"
```

Then install in post-install.sh:
```bash
sudo pacman -S --needed --noconfirm $CUSTOM_PACKAGES
```

### Adjusting Partitions

Edit partition sizes in `arch-install.sh`:

```bash
EFI_SIZE="1GiB"      # Increase EFI partition
ROOT_SIZE="150GiB"   # Larger root
HOME_SIZE="300GiB"   # Larger home
SWAP_SIZE="16GiB"    # More swap
```

### Skipping Components

Disable optional components in `config.example`:

```bash
INSTALL_HYDE="no"        # Skip HyDE dotfiles
ENABLE_FIREWALL="no"     # Skip firewall setup
```

## 🔍 Troubleshooting

### Installation Issues

**Problem: "System is not booted in UEFI mode"**
- **Solution:** Ensure UEFI boot in BIOS settings, not Legacy/CSM

**Problem: "No internet connection"**
- **Solution:** Configure network before running script:
  ```bash
  # Wired
  dhcpcd
  
  # Wireless
  iwctl
  station wlan0 connect "SSID"
  ```

**Problem: "Disk validation failed"**
- **Solution:** Verify disk path with `lsblk -d` and ensure sufficient space

**Problem: Installation hangs during pacstrap**
- **Solution:** Check mirror list, update with `reflector`:
  ```bash
  reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
  ```

### Post-Installation Issues

**Problem: Display manager doesn't start**
- **Solution:** Check SDDM status:
  ```bash
  sudo systemctl status sddm
  sudo journalctl -xeu sddm
  ```

**Problem: Hyprland won't start**
- **Solution:** Check logs:
  ```bash
  cat /tmp/hypr/*/hyprland.log
  ```

**Problem: AUR helper installation fails**
- **Solution:** Install dependencies first:
  ```bash
  sudo pacman -S --needed base-devel git
  ```

### Manual Recovery Commands

If automation fails, manual installation steps:

```bash
# Partition disk
gdisk /dev/sda
# Create partitions: EFI, root, home, swap, data

# Format
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2
mkfs.ext4 /dev/sda3
mkswap /dev/sda4
mkfs.ext4 /dev/sda5

# Mount
mount /dev/sda2 /mnt
mkdir /mnt/boot /mnt/home /mnt/data
mount /dev/sda1 /mnt/boot
mount /dev/sda3 /mnt/home
mount /dev/sda5 /mnt/data
swapon /dev/sda4

# Install base
pacstrap -K /mnt base linux linux-firmware

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot and configure
arch-chroot /mnt
```

## 📚 References

- [Arch Linux Installation Guide](https://wiki.archlinux.org/title/Installation_guide)
- [Hyprland Documentation](https://wiki.hyprland.org/)
- [HyDE GitHub Repository](https://github.com/prasanthrangan/hyprdots)
- [systemd-boot](https://wiki.archlinux.org/title/Systemd-boot)
- [Arch User Repository](https://wiki.archlinux.org/title/Arch_User_Repository)

## 🔐 Security Considerations

The scripts implement several security best practices:

1. **Password Security**
   - Never hardcoded in scripts
   - Always prompted with hidden input (`read -s`)
   - Separate root and user passwords

2. **Sudo Configuration**
   - Wheel group for sudo access
   - Reasonable timeout
   - Editor set to vim

3. **SSH Hardening**
   - Root login disabled
   - Key-based authentication preferred
   - Configured automatically

4. **Firewall**
   - UFW installed and configured
   - Default deny incoming
   - SSH allowed

5. **System Updates**
   - Intel microcode for CPU security patches
   - Automatic time synchronization

## 📝 Logs

All operations are logged for troubleshooting:

- **Installation log:** `/tmp/arch-install.log`
- **Post-install log:** `/tmp/arch-post-install.log`
- **State file:** `/tmp/install-state.conf`

## 🤝 Contributing

Contributions are welcome! Areas for improvement:
- Additional desktop environment options
- Support for other bootloaders (GRUB)
- Encryption setup (LUKS)
- Multi-boot configurations
- Additional hardware profiles

## 📄 License

These scripts are provided as-is for educational and personal use.

## ⚠️ Disclaimer

**WARNING:** These scripts will **destroy all data** on the selected disk. Always:
- Backup important data before proceeding
- Verify disk selection carefully
- Test in a virtual machine first
- Understand each step before running

The authors are not responsible for data loss or system damage.

## 🎓 Learning Resources

New to Arch Linux? Start here:
- [Arch Linux Wiki](https://wiki.archlinux.org/)
- [Arch Linux Installation Guide (Official)](https://wiki.archlinux.org/title/Installation_guide)
- [General Recommendations](https://wiki.archlinux.org/title/General_recommendations)
- [Hyprland Wiki](https://wiki.hyprland.org/)

---

**Created for:** Dell OptiPlex 3040 MT  
**Last Updated:** December 2025  
**Maintainer:** TZK-KG
