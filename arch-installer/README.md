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

### 2. Kernel Parameters
- **elevator=noop**: Optimized I/O scheduler for SSDs/USB drives
- Reduces unnecessary seek operations

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
