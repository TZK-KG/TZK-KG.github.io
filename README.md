# TZK-KG.github.io

Arch Linux installation scripts for USB drives with Hyprland desktop environment.

## 📦 Available Installers

### 🚀 Full Version (256GB USB)
**Location:** [`arch-installer/`](arch-installer/)

A comprehensive Arch Linux installation for 256GB+ USB drives with full development environment:
- **Target:** 256GB USB 3.0+ drives
- **Dotfiles:** HyDE (prasanthrangan/hyprdots)
- **Features:** Docker, VS Code, Postman, multiple browsers
- **Size:** ~20-30GB installed
- **Use case:** Complete development workstation

[View Full Documentation →](arch-installer/README.md)

### ⚡ Lightweight Version (32GB USB)
**Location:** [`arch-installer-32gb/`](arch-installer-32gb/)

A lightweight, minimal Arch Linux installation for 32GB USB drives:
- **Target:** 32GB USB 3.0+ drives
- **Dotfiles:** end4 (end-4/dots-hyprland)
- **Features:** Minimal packages, single browser, Python only
- **Size:** ~8-10GB installed
- **Use case:** Portable, lightweight system

[View Lightweight Documentation →](arch-installer-32gb/README.md)

## 🔍 Comparison

| Feature | Full (256GB) | Lightweight (32GB) |
|---------|-------------|-------------------|
| Disk Size | 256GB+ | 32GB+ |
| Root Partition | 60-100GB | 15GB |
| Home Partition | 80-200GB | 10GB |
| Dotfiles | HyDE | end4 |
| Docker | ✓ | ✗ |
| VS Code | ✓ | ✗ |
| Browsers | 3 | 1 |
| Development | Full stack | Python only |
| Size | 20-30GB | 8-10GB |

## 🚀 Quick Start

### For Full Version (256GB)
```bash
curl -L https://github.com/TZK-KG/TZK-KG.github.io/archive/refs/heads/main.tar.gz | tar xz
cd TZK-KG.github.io-main/arch-installer
chmod +x *.sh
./arch-install.sh
```

### For Lightweight Version (32GB)
```bash
curl -L https://github.com/TZK-KG/TZK-KG.github.io/archive/refs/heads/main.tar.gz | tar xz
cd TZK-KG.github.io-main/arch-installer-32gb
chmod +x *.sh
./arch-install.sh
```

## 📖 Documentation

- [Full Version (256GB) README](arch-installer/README.md)
- [Lightweight Version (32GB) README](arch-installer-32gb/README.md)

## 🎯 Which Version Should I Use?

**Choose Full Version (256GB) if:**
- You have a large USB drive (256GB+)
- You need a complete development environment
- You want Docker, VS Code, and multiple browsers
- Storage space is not a concern
- You prefer HyDE dotfiles

**Choose Lightweight Version (32GB) if:**
- You have a smaller USB drive (32GB)
- You want a minimal, fast system
- You prefer end4 dotfiles
- You want to maximize USB drive longevity
- You need a portable system with minimal footprint

## 🔧 Features Common to Both Versions

- ✅ UEFI-only installation
- ✅ Hyprland Wayland compositor
- ✅ Automated installation with checkpoint system
- ✅ USB longevity optimizations (noatime, zram)
- ✅ Security hardening (UFW, SSH)
- ✅ Pre-seeding support for unattended installations
- ✅ Comprehensive error handling

## 🔧 ISO Builder Tool

Want to create bootable ISOs from these installation scripts? Check out the **[ISO Builder](iso-builder/)** - a GUI and CLI tool for building custom Arch Linux ISOs.

### Quick Start with ISO Builder
```bash
cd iso-builder
./build-iso.sh
```

Features:
- Interactive GUI (zenity/dialog support)
- Command-line interface for automation
- Build 256GB or 32GB versions (or both)
- GitHub integration or local source support

[Learn more →](iso-builder/README.md)

## 📝 License

These scripts are provided as-is for educational and personal use.

## ⚠️ Warning

These scripts will **destroy all data** on the selected disk. Always backup important data before proceeding.