# Arch Linux 32GB USB Installation Scripts

Lightweight, portable Arch Linux installation scripts optimized for 32GB USB drives with Hyprland and end4 dotfiles.

## 🎯 Overview

This is a **lightweight 32GB version** of the Arch Linux USB installer, designed for:
- **32GB USB 3.0+ drives** (minimum 30GB)
- **Portable usage** across different systems
- **Minimal footprint** (~8-10GB installed size)
- **end4 dotfiles** instead of HyDE for a modern, efficient interface
- **USB longevity** optimizations

### Key Differences from Full Version (256GB)

| Feature | Full Version | 32GB Lightweight |
|---------|-------------|------------------|
| Target Size | 256GB | 32GB |
| Root Partition | 60-100GB | 15GB |
| Home Partition | 80-200GB | 10GB |
| Swap | 8GB | 4GB |
| Dotfiles | HyDE | end4 |
| Docker | ✓ | ✗ |
| VS Code | ✓ | ✗ |
| Browsers | 3 (Firefox, Chromium, Brave) | 1 (Firefox) |
| Development | Node.js, Python | Python only |
| Installed Size | 20-30GB | 8-10GB |

## 📋 Features

- ✅ UEFI-only installation with systemd-boot
- ✅ Optimized for 32GB USB drives
- ✅ **end4 dotfiles** - Modern, lightweight Hyprland configuration
- ✅ Minimal package selection (no bloat)
- ✅ USB longevity optimizations (noatime, zram, reduced logging)
- ✅ Checkpoint system for resuming failed installations
- ✅ Colorized output with progress indicators
- ✅ Pre-seeding support for unattended installations
- ✅ Security hardening (UFW firewall, SSH)

## 🖥️ Target Hardware

**Optimized for:**
- Any UEFI-compatible system
- Dell OptiPlex 3040 MT and similar
- Minimum 4GB RAM (8GB+ recommended)
- 32GB USB 3.0 or higher drive

**Partition Scheme (32GB USB):**
- 512MB EFI System Partition (FAT32)
- 15GB Root partition (ext4)
- 10GB Home partition (ext4)
- 4GB Swap partition (with zram option)
- ~2GB Data partition (ext4)

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
   cd TZK-KG.github.io-main/arch-installer-32gb
   chmod +x *.sh
   ```

2. **Run the main installation script:**
   ```bash
   ./arch-install.sh
   ```

3. **Follow the prompts:**
   - Select installation disk (your USB drive)
   - Set hostname, username, passwords
   - Configure timezone and locale
   - Confirm installation

4. **After reboot, login and run post-installation:**
   ```bash
   ./post-install.sh
   ```

5. **Reboot and enjoy your lightweight Arch Linux system!**

## 📖 Detailed Usage

### Interactive Installation (Default)

```bash
./arch-install.sh
```

You'll be prompted for:
- USB drive selection (with size verification)
- Hostname (default: arch-32gb-usb)
- Username
- Root password
- User password
- Timezone (auto-detected)
- Locale
- Optional components (end4, firewall)

### Automated Installation

1. **Create configuration:**
   ```bash
   cp config.example my-config.conf
   nano my-config.conf
   ```

2. **Configure your settings:**
   ```bash
   DISK="/dev/sdb"
   HOSTNAME="myarch"
   USERNAME="myuser"
   TIMEZONE="America/New_York"
   INSTALL_END4="yes"
   ```

3. **Run installer:**
   ```bash
   ./arch-install.sh
   ```

## 📦 Installed Software

### Base System (Minimal)
- **Kernel:** linux, linux-headers, linux-firmware
- **Essential:** base, base-devel, networkmanager
- **CPU:** intel-ucode (microcode updates)
- **Tools:** git, wget, curl, vim, nano

### Desktop Environment (Lightweight)
- **Compositor:** Hyprland (Wayland)
- **Bar:** Waybar
- **Terminal:** Kitty
- **Launcher:** Rofi (Wayland)
- **Notifications:** Mako
- **File Manager:** Thunar
- **Display Manager:** SDDM
- **Dotfiles:** end4 (from end-4/dots-hyprland)

### Browser (Single)
- Firefox (official repo only)

### Development (Minimal)
- Python with pip

### System Utilities (Essential)
- **Monitoring:** htop
- **System Info:** fastfetch
- **Documentation:** man-db, man-pages

### Security & Network
- **Firewall:** UFW (optional)
- **SSH:** OpenSSH (hardened configuration)
- **VPN:** Tailscale - Secure mesh VPN for remote access
  - Zero-config VPN based on WireGuard
  - Provides secure remote SSH access
  - Works across NAT and firewalls
  - Easy authentication: `sudo tailscale up`
  - Free for personal use (up to 100 devices)
  - [Tailscale Documentation](https://tailscale.com/kb/)

### AUR Helper
- **yay** - Yet Another Yogurt (minimal install)

## 🎨 end4 Dotfiles

This installer uses **end4 dotfiles** instead of HyDE for a lighter, more modern experience.

### What is end4?

end4 (from [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)) provides:
- Modern, clean Hyprland configuration
- AGS (Aylur's GTK Shell) for beautiful widgets
- Smooth animations and transitions
- Lightweight and efficient
- Easy customization
- Active development

### end4 Features

- ✨ Beautiful, modern interface
- 🚀 Lightweight and fast
- 🎨 Customizable themes and colors
- 📊 System monitoring widgets
- 🔊 Audio controls
- 🌐 Network management
- 📱 Mobile-inspired design
- ⌨️ Keyboard-driven workflow

### Configuration Locations

- AGS: `~/.config/ags/`
- Hyprland: `~/.config/hypr/`
- Waybar: `~/.config/waybar/`
- Kitty: `~/.config/kitty/`

## 🌐 Using Tailscale VPN

Tailscale provides secure remote access to your portable Arch system from anywhere.

### Initial Setup

After installation, authenticate with Tailscale:

```bash
sudo tailscale up
```

This will:
1. Generate a unique authentication URL
2. Open your browser to sign in (or display a URL to visit)
3. Connect your device to your Tailscale network

### Common Use Cases

**Remote SSH Access:**
```bash
# From another Tailscale-connected device
ssh username@100.x.y.z  # Use your Tailscale IP
```

**File Transfer:**
```bash
# Use scp with Tailscale IP
scp file.txt username@100.x.y.z:~/
```

**Access from Mobile:**
- Install Tailscale on your phone
- SSH using apps like Termius or JuiceSSH
- Access your portable Arch system wherever you are

### Tailscale Commands

```bash
# Check connection status
tailscale status

# Disconnect
sudo tailscale down

# Reconnect
sudo tailscale up

# Get your Tailscale IP
tailscale ip -4
```

### Security Benefits

- ✓ End-to-end encrypted (WireGuard)
- ✓ Works behind NAT/firewalls
- ✓ No port forwarding needed
- ✓ Zero trust network access
- ✓ Easy device management via web dashboard

## 🔧 USB-Specific Optimizations

The installation includes several optimizations for USB drive longevity:

### 1. Mount Options
- **noatime**: Reduces write operations by not updating file access timestamps
- Applied automatically to all ext4 partitions

### 2. zram Swap
- Swap in compressed RAM instead of USB
- Configured automatically (4GB zram)
- Reduces physical writes to USB drive
- Verify after reboot: `zramctl`

### 3. Reduced Logging
- Journal limited to 50MB
- Reduces constant writes to USB
- Configured in `/etc/systemd/journald.conf.d/`

### 4. Sysctl Optimizations
- `vm.swappiness=10` - Minimal swap usage
- `vm.dirty_ratio=5` - Faster writeback
- `vm.dirty_background_ratio=3` - Reduced dirty pages

### 5. I/O Scheduler
- Modern Linux kernels (5.0+) automatically select appropriate I/O schedulers
- Optimized for flash storage

## 📊 Comparison: Full vs. Lightweight

### Disk Space Usage

```
Full Version (256GB):
├── System: ~15-20GB
├── Applications: ~10GB
├── Docker images: ~5-10GB
├── Development tools: ~5GB
└── Available: ~200GB+

Lightweight (32GB):
├── System: ~5-6GB
├── Applications: ~2-3GB
├── Available: ~20GB+
```

### Package Count

- **Full Version:** ~60+ official packages, 4 AUR packages
- **Lightweight:** ~35 official packages, 1 AUR package (AGS)

### Installation Time

- **Full Version:** 45-90 minutes
- **Lightweight:** 15-30 minutes

## 🛠️ Customization

### Adding Packages

Edit `packages.conf` to add packages:

```bash
# Add to existing group
UTIL_PACKAGES="$UTIL_PACKAGES neofetch"

# Uncomment optional packages
# AUDIO_PACKAGES="pipewire pipewire-pulse"
```

### Adjusting Partitions

Edit partition sizes in `config.example`:

```bash
ROOT_SIZE="20GiB"   # Larger root
HOME_SIZE="8GiB"    # Smaller home
```

### Customizing end4

After installation, customize end4:

```bash
# Edit Hyprland config
vim ~/.config/hypr/hyprland.conf

# Edit AGS config
vim ~/.config/ags/config.js

# Reload Hyprland
hyprctl reload
```

## 🔍 Troubleshooting

### Installation Issues

**Problem: Disk too small**
- **Solution:** Use a 32GB or larger USB drive. Minimum 30GB required.

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

### Post-Installation Issues

**Problem: end4 not loading**
- **Solution:** Check AGS status:
  ```bash
  ags --version
  ags
  ```

**Problem: Display manager doesn't start**
- **Solution:** Check SDDM status:
  ```bash
  sudo systemctl status sddm
  sudo journalctl -xeu sddm
  ```

**Problem: zram not active**
- **Solution:** Check zram status:
  ```bash
  zramctl
  # If not shown, enable it:
  sudo systemctl enable systemd-zram-setup@zram0.service
  ```

## 💾 USB Longevity Tips

1. **Use zram for swap** (automatically configured)
   - Keeps swap in RAM, not on USB
   - Reduces write cycles

2. **Minimize writes**
   - Browser cache in RAM
   - Log files limited
   - noatime mount option

3. **Regular backups**
   - USB drives have limited write cycles
   - Backup important data regularly

4. **Monitor drive health**
   ```bash
   sudo smartctl -a /dev/sdX
   ```

5. **Use quality USB drives**
   - USB 3.0 or higher
   - From reputable manufacturers
   - Consider industrial-grade drives

## 📚 References

- [Arch Linux Installation Guide](https://wiki.archlinux.org/title/Installation_guide)
- [Hyprland Documentation](https://wiki.hyprland.org/)
- [end4 Dotfiles](https://github.com/end-4/dots-hyprland)
- [AGS Documentation](https://github.com/Aylur/ags)
- [USB Installation](https://wiki.archlinux.org/title/Install_Arch_Linux_on_a_removable_medium)

## 🔐 Security Considerations

1. **Password Security**
   - Never hardcoded in scripts
   - Always prompted with hidden input
   - Separate root and user passwords

2. **Sudo Configuration**
   - Wheel group for sudo access
   - Reasonable timeout

3. **SSH Hardening**
   - Root login disabled
   - Key-based authentication preferred

4. **Firewall**
   - UFW installed and configured
   - Default deny incoming
   - SSH allowed

## 📝 Logs

All operations are logged:
- **Installation log:** `/tmp/arch-install-32gb.log`
- **Post-install log:** `/tmp/arch-post-install-32gb.log`
- **State file:** `/tmp/install-state-32gb.conf`

## 🤝 Contributing

Contributions are welcome! Areas for improvement:
- Additional lightweight optimizations
- More end4 customization options
- Battery optimization for laptops
- Alternative dotfiles support

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

- [Arch Linux Wiki](https://wiki.archlinux.org/)
- [Hyprland Wiki](https://wiki.hyprland.org/)
- [end4 Repository](https://github.com/end-4/dots-hyprland)
- [AGS Documentation](https://github.com/Aylur/ags)

---

**Version:** 32GB Lightweight  
**Dotfiles:** end4 (end-4/dots-hyprland)  
**Last Updated:** December 2024  
**Maintainer:** TZK-KG
