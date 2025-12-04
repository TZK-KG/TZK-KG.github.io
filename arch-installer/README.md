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
# Arch Linux USB Installation Script

Automated installation script for Arch Linux on a 256GB USB drive, optimized for portable usage and USB longevity.

## Overview

This installation script creates a fully functional Arch Linux system on a 256GB USB 3.0/3.1 drive that can boot on any UEFI-compatible system. It includes optimizations specifically designed for USB drive longevity and performance.

## Target System

- **Storage**: 256GB USB 3.0/3.1 drive (minimum 200GB)
- **Boot Mode**: UEFI
- **Compatibility**: Dell OptiPlex 3040 MT and any UEFI system
- **Usage**: Portable USB installation

## Partition Layout (256GB USB Drive)

| Partition | Mount Point | Size | Filesystem | Purpose |
|-----------|-------------|------|------------|---------|
| 1 | /boot/efi | 512MB | FAT32 | EFI System Partition |
| 2 | / | 60GB | ext4 | Root filesystem |
| 3 | /home | 80GB | ext4 | User home directory |
| 4 | swap | 8GB | swap | Swap space |
| 5 | /data | ~105GB | ext4 | Additional data storage |

**Total: ~256GB**

### Partition Size Comparison (4TB vs 256GB)

| Partition | Old Size (4TB) | New Size (256GB) |
|-----------|----------------|------------------|
| EFI | 512MB | 512MB (unchanged) |
| Root | 100GB | 60GB |
| Home | 200GB | 80GB |
| Swap | 8GB | 8GB (unchanged) |
| Data | ~3.6TB remaining | ~105GB remaining |

## USB-Specific Optimizations

The installation script includes several optimizations for USB drive longevity and performance:

### 1. Mount Options
- **noatime**: Reduces write operations by not updating file access timestamps
- Applied automatically to all ext4 partitions during fstab generation

### 2. I/O Scheduler
- Modern Linux kernels (5.0+) automatically select appropriate I/O schedulers
- Optimized for SSD/USB flash storage
- No manual configuration needed

### 3. Filesystem Choices
- **ext4**: Reliable and well-tested for USB drives
- **Alternative**: Consider f2fs for root partition for better flash performance (manual modification required)

### 4. Swap Optimization
- Standard swap partition (8GB)
- **Optional**: Consider zram as an alternative to reduce USB wear
  - Compresses swap in RAM
  - Reduces physical writes to USB drive

### 5. Write Reduction
- noatime mount option enabled by default
- Reduces unnecessary metadata updates
- Extends USB drive lifespan

## Prerequisites

1. **Boot from Arch Linux ISO**
   - Download from: https://archlinux.org/download/
   - Create bootable USB with `dd` or Rufus

2. **UEFI Boot Mode**
   - Ensure system is booted in UEFI mode (not Legacy/BIOS)
   - Check with: `ls /sys/firmware/efi`

3. **Internet Connection**
   - Required for downloading packages
   - Connect via Ethernet or WiFi

4. **Target USB Drive**
   - Minimum 200GB (256GB recommended)
   - USB 3.0 or 3.1 for better performance
   - **WARNING**: All data will be erased!

## Installation Steps

### 1. Boot Arch Linux Installation Media

Boot your system from the Arch Linux installation ISO.

### 2. Connect to Internet

**For Ethernet:**
```bash
# Usually works automatically
ping archlinux.org
```

**For WiFi:**
```bash
iwctl
[iwd]# device list
[iwd]# station wlan0 scan
[iwd]# station wlan0 get-networks
[iwd]# station wlan0 connect "Your-SSID"
[iwd]# exit
```

### 3. Download Installation Script

```bash
# Install git
pacman -Sy git

# Clone repository
git clone https://github.com/TZK-KG/TZK-KG.github.io.git
cd TZK-KG.github.io/arch-installer
```

### 4. Configure Installation (Optional)

Copy and edit the example configuration:

```bash
cp config.example config.conf
vim config.conf
```

Edit the following variables:
- `DISK`: Target USB drive (e.g., /dev/sdb)
- `HOSTNAME`: System hostname
- `USERNAME`: Primary user account
- `TIMEZONE`: Your timezone
- `LOCALE`: System locale
- `KEYMAP`: Keyboard layout

### 5. Customize Packages (Optional)

Edit `packages.conf` to add or remove packages:

```bash
vim packages.conf
```

### 6. Run Installation Script

```bash
chmod +x arch-install.sh
./arch-install.sh
```

The script will:
1. Check system requirements
2. Prompt for disk selection (if not in config)
3. Partition and format the USB drive
4. Install base system
5. Configure system settings
6. Install bootloader (GRUB)
7. Install additional packages
8. Apply USB optimizations

### 7. Reboot

```bash
reboot
```

Remove the installation media and boot from the USB drive.

## Post-Installation

### First Boot

1. Boot from the USB drive
2. Log in with the user account created during installation
3. Update system: `sudo pacman -Syu`

### Recommended Post-Installation Steps

1. **Configure Network**
   ```bash
   sudo systemctl start NetworkManager
   sudo systemctl enable NetworkManager
   nmtui  # Text UI for network configuration
   ```

2. **Install Desktop Environment** (Optional)
   ```bash
   # Example: Install XFCE
   sudo pacman -S xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
   sudo systemctl enable lightdm
   ```

3. **Setup Zram for Swap** (Optional - reduces USB writes)
   ```bash
   sudo pacman -S zram-generator
   sudo nano /etc/systemd/zram-generator.conf
   ```
   
   Add:
   ```ini
   [zram0]
   zram-size = ram / 2
   compression-algorithm = zstd
   ```
   
   Then reboot and verify:
   ```bash
   zramctl
   ```

4. **Install AUR Helper** (Optional)
   ```bash
   git clone https://aur.archlinux.org/yay.git
   cd yay
   makepkg -si
   ```

5. **Configure Power Management** (For laptops)
   ```bash
   sudo pacman -S tlp
   sudo systemctl enable tlp
   sudo systemctl start tlp
   ```

## USB Drive Longevity Tips

1. **Minimize Writes**
   - Use browser cache in RAM
   - Move log files to tmpfs
   - Use zram for swap

2. **Regular Backups**
   - USB drives have limited write cycles
   - Backup important data regularly

3. **Monitor Drive Health**
   ```bash
   sudo smartctl -a /dev/sdX
   ```

4. **Avoid Frequent Repartitioning**
   - The partition scheme is designed to be permanent

5. **Use Quality USB Drives**
   - USB 3.0 or higher
   - From reputable manufacturers
   - Consider industrial-grade USB drives for heavy use

## Troubleshooting

### Boot Issues

**System doesn't boot from USB:**
- Check BIOS/UEFI settings
- Disable Secure Boot if necessary
- Ensure USB drive is set as first boot device

**GRUB errors:**
- Boot from Arch ISO
- Mount partitions and chroot
- Reinstall GRUB:
  ```bash
  mount /dev/sdX2 /mnt
  mount /dev/sdX1 /mnt/boot/efi
  arch-chroot /mnt
  grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ARCH --removable
  grub-mkconfig -o /boot/grub/grub.cfg
  ```

### Performance Issues

**Slow boot or operation:**
- Ensure using USB 3.0 port
- Check if noatime is enabled: `cat /etc/fstab`
- Consider upgrading to faster USB drive

### Partition Issues

**Out of space:**
- Check partition usage: `df -h`
- Clean package cache: `sudo pacman -Sc`
- Remove unused packages: `sudo pacman -Rns $(pacman -Qtdq)`

## File Structure

```
arch-installer/
├── arch-install.sh     # Main installation script
├── config.example      # Example configuration file
├── packages.conf       # List of packages to install
└── README.md          # This file
```

## Configuration Files

### config.example
Template configuration file with all available options and defaults for 256GB USB installation.

### packages.conf
List of additional packages to install. Includes common utilities, desktop environments, and development tools. Optimized for portable USB installation.

## Security Considerations

1. **Secure Boot**: Script uses `--removable` flag for GRUB to maximize compatibility
2. **Encryption**: Not included by default (adds complexity for portable use)
3. **Firewall**: Consider installing and configuring UFW or firewalld

## Contributing

Feel free to submit issues or pull requests to improve the installation script.

## License

This script is provided as-is for educational and personal use.

## References

- [Arch Linux Installation Guide](https://wiki.archlinux.org/title/Installation_guide)
- [Arch Linux USB Installation](https://wiki.archlinux.org/title/Install_Arch_Linux_on_a_removable_medium)
- [Improving Performance](https://wiki.archlinux.org/title/Improving_performance)
- [SSD Optimization](https://wiki.archlinux.org/title/Solid_state_drive)
