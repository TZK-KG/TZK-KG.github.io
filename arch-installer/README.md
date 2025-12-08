# Arch Linux Installation Scripts

Comprehensive, production-ready Arch Linux installation scripts for automated deployment. Designed specifically for Dell OptiPlex 3040 MT systems but adaptable to most UEFI-based hardware.

## 🎯 Overview

This installation suite provides a complete, automated Arch Linux setup with:
- **Hyprland** - Modern tiling Wayland compositor
- **end4 dotfiles** - User dotfiles (replaceable; configurable)
- **Full development environment** - Docker, VS Code, Node.js, Python
- **Security hardened** - UFW firewall, SSH hardening, sudo configuration
- **AUR support** - Both yay and paru pre-installed

> Note: The installer was updated to use end4 dotfiles by default instead of HyDE. You can change the dotfiles repo or disable dotfiles installation in your configuration.

## 📋 Features

- ✅ UEFI-only installation with systemd-boot
- ✅ Automated partitioning with intelligent disk layout
- ✅ Checkpoint system for resuming failed installations
- ✅ Colorized output with progress indicators
- ✅ Comprehensive error handling and logging
- ✅ Pre-seeding support for unattended installations
- ✅ Modular package organization
- ✅ Post-installation automation (now installs end4 dotfiles by default)
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

## 🚀 Quick Start — updated for end4 dotfiles

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

### Installation Steps (summary)

1. Download the scripts:
   ```bash
   curl -L https://github.com/TZK-KG/TZK-KG.github.io/archive/refs/heads/main.tar.gz | tar xz
   cd TZK-KG.github.io-main/arch-installer
   chmod +x *.sh
   ```

2. Edit `config.example` (or create `my-config.conf`) and set DOTFILES options (example below).

3. Run the main installation script:
   ```bash
   ./arch-install.sh
   ```

4. After reboot, login and run post-installation (if necessary):
   ```bash
   ./post-install.sh
   ```

5. Reboot and enjoy your new Arch Linux system (with end4 dotfiles applied).

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
- Optional components (end4 dotfiles, firewall)

### Automated Installation

For unattended installs, use pre-seeding configuration:

1. Create configuration:
   ```bash
   cp config.example my-config.conf
   nano my-config.conf
   ```

2. Configure your settings and dotfiles options:
   ```bash
   DISK="/dev/sda"
   HOSTNAME="myarch"
   USERNAME="myuser"
   TIMEZONE="America/New_York"
   AUTOMATION_MODE="automatic"

   # Dotfiles section (new)
   INSTALL_DOTFILES="yes"                 # yes/no
   DOTFILES_REPO="https://github.com/end4/dotfiles.git"  # set your dotfiles repo
   DOTFILES_INSTALL_CMD="./install.sh"    # command inside the dotfiles repo to run
   ```

3. Run installer:
   ```bash
   ./arch-install.sh
   ```
   When prompted, load your configuration file (or pass it to the script if the script supports that flag).

### Resuming After Failure

If installation fails, the checkpoint system allows resuming:

```bash
./arch-install.sh
# Choose "yes" when asked to resume from checkpoint
```

## 📦 Installed Software

... (same as before) ...

### Dotfiles
- end4 dotfiles (optional, configurable)
  - The installer will clone the repository specified by DOTFILES_REPO and run the command specified in DOTFILES_INSTALL_CMD as the created user. Set INSTALL_DOTFILES="no" to skip.

## 🔧 Configuration Files

### arch-install.sh
Main installation script with modular functions:
- Pre-flight checks (UEFI, internet, disk)
- User input collection
- Disk partitioning with parted
- Base system installation
- Chroot configuration execution
- Checkpoint system
- Dotfiles install logic: clones DOTFILES_REPO and runs DOTFILES_INSTALL_CMD as the target user (configurable)

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
- end4 dotfiles installation (optional)
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
Pre-seeding configuration template for automated installations. New dotfiles variables added:
```bash
INSTALL_DOTFILES="yes"
DOTFILES_REPO="https://github.com/end4/dotfiles.git"
DOTFILES_INSTALL_CMD="./install.sh"
```

## 🛠️ Easy step-by-step Guide (simple & explicit)

This guide is for a typical interactive installation using end4 dotfiles.

1. Boot the machine from an Arch Linux ISO in UEFI mode.
2. Ensure you have a working Internet connection:
   - Wired typically works automatically.
   - For WiFi:
     - Run `iwctl`
     - `station <your-device> scan`
     - `station <your-device> get-networks`
     - `station <your-device> connect "SSID"`
     - Exit `iwctl`.
   - Test: `ping -c 3 archlinux.org`

3. Prepare the installer:
   ```bash
   pacman -Sy --noconfirm git curl
   curl -L https://github.com/TZK-KG/TZK-KG.github.io/archive/refs/heads/main.tar.gz | tar xz
   cd TZK-KG.github.io-main/arch-installer
   chmod +x *.sh
   ```

4. Create a configuration (optional but recommended):
   ```bash
   cp config.example my-config.conf
   nano my-config.conf
   ```
   At minimum set:
   - DISK (e.g. /dev/sda)
   - HOSTNAME
   - USERNAME
   - TIMEZONE
   - INSTALL_DOTFILES="yes"
   - DOTFILES_REPO (set to end4 dotfiles repo or your fork)
   - DOTFILES_INSTALL_CMD (if install script has a different name)

5. Inspect the script briefly to confirm dotfiles behavior:
   - Search for DOTFILES_REPO and DOTFILES_INSTALL_CMD in `arch-install.sh` or `post-install.sh`.
   - Confirm that the dotfiles clone and install step will run as the created user.

6. Run the installer:
   ```bash
   ./arch-install.sh
   ```
   - Choose interactive mode unless you provided `AUTOMATION_MODE="automatic"`.
   - Follow prompts carefully (disk selection will wipe target disk).

7. After the first successful chroot & install, reboot:
   ```bash
   reboot
   ```
   - Remove the installation medium and boot the new system.

8. On first boot:
   - Login as the user you created.
   - If the README or installer indicates to run post-install:
     ```bash
     cd ~/arch-installer
     chmod +x post-install.sh
     ./post-install.sh
     ```
   - The post-install script will (if enabled in config) clone the end4 dotfiles repo into the user's home (e.g. /home/myuser/.dotfiles) and run the install command you configured.

9. Verify the dotfiles applied:
   - Check dotfiles folder: `ls -la ~/.dotfiles`
   - Run any dotfiles-provided setup commands (the installer normally does this).
   - Confirm desktop (Hyprland) starts, or services are enabled.

10. Final steps:
    ```bash
    sudo pacman -Syu
    # for AUR packages, use yay/paru installed by post-install
    ```

If anything fails, consult the log files:
- /tmp/arch-install.log
- /tmp/arch-post-install.log
- /tmp/install-state.conf

## 🔍 Troubleshooting

(unchanged — use the existing troubleshooting sections; dotfiles-specific issues:)
- If dotfiles install fails:
  - Check network in the installed system
  - Ensure `git` is installed and DOTFILES_REPO is reachable
  - Manually clone and run the install in the user account:
    ```bash
    git clone <DOTFILES_REPO> ~/.dotfiles
    cd ~/.dotfiles
    $DOTFILES_INSTALL_CMD
    ```

## 🔐 Security Considerations

(unchanged; dotfiles repo is external — review before running):
- Review the contents of any dotfiles repo before running their install script.
- Prefer to fork end4 dotfiles into your own repo and review/modify the install script before using in automated installs.

## 🤝 Contributing

Contributions are welcome! If you updated the installer to use a different dotfiles repository, please open a PR explaining the change and any compatibility notes.

## 📄 License

These scripts are provided as-is for educational and personal use.

## ⚠️ Disclaimer

**WARNING:** These scripts will **destroy all data** on the selected disk. Always:
- Backup important data before proceeding
- Verify disk selection carefully
- Test in a virtual machine first
- Understand each step before running

The authors are not responsible for data loss or system damage.

---
