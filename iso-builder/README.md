# Arch Linux ISO Builder with GUI

A user-friendly tool for creating bootable Arch Linux ISOs from installation scripts. Features both a graphical interface (GUI) and command-line interface (CLI) for flexibility.

## Overview

This ISO builder allows you to package the Arch Linux installation scripts into bootable ISO images that can be used to install Arch Linux on target systems. The tool supports multiple installation profiles and provides an easy-to-use interface for customization.

## Features

### GUI Features
- **Interactive Dialogs** - User-friendly GUI using zenity (GTK) or dialog (TUI)
- **Source Selection** - Choose between local files or GitHub repository
- **Version Selection** - Build 256GB version, 32GB version, or both
- **Output Configuration** - Customize output directory and ISO names
- **Progress Indicators** - Visual feedback during the build process
- **Error Handling** - Clear error messages and validation

### Technical Features
- **Automatic Dependency Management** - Checks and offers to install missing dependencies
- **Dual Mode Operation** - Both GUI and CLI modes supported
- **GitHub Integration** - Direct cloning from GitHub repositories
- **Archiso Integration** - Uses official archiso tools for ISO creation
- **Disk Space Validation** - Ensures sufficient space before building
- **Build Logging** - Detailed logs for troubleshooting

## Requirements

### System Requirements
- **OS**: Arch Linux or Arch-based distribution
- **Disk Space**: At least 4GB free in /tmp
- **Architecture**: x86_64 (UEFI)

### Dependencies
Required packages:
- `archiso` - Official Arch Linux ISO building tools
- `git` - For cloning GitHub repositories
- `zenity` or `dialog` - For GUI/TUI dialogs (at least one required for GUI mode)
- `sudo` - For root operations (or run as root)

The script will automatically detect missing dependencies and offer to install them.

### Installation

Install dependencies on Arch Linux:
```bash
sudo pacman -S archiso git zenity
```

Or for TUI-only mode:
```bash
sudo pacman -S archiso git dialog
```

## Usage

### GUI Mode (Interactive)

Simply run the script without arguments to launch the interactive GUI:

```bash
./build-iso.sh
```

The GUI will guide you through:
1. Source selection (local directory or GitHub URL)
2. Version selection (256GB, 32GB, or both)
3. Output directory selection
4. ISO name customization
5. Build confirmation
6. Progress monitoring

### CLI Mode (Command Line)

For automated builds or scripting, use CLI mode:

```bash
./build-iso.sh --cli --source <path|url> --version <version> --output <dir>
```

#### CLI Options

| Option | Description | Example |
|--------|-------------|---------|
| `--cli` | Enable CLI mode (no GUI) | `--cli` |
| `--source PATH` | Source directory or GitHub URL | `--source /path/to/repo` |
| `--github URL` | GitHub repository URL | `--github https://github.com/user/repo` |
| `--local PATH` | Local directory path | `--local /path/to/repo` |
| `--version VERSION` | Version: `256gb`, `32gb`, or `both` | `--version 256gb` |
| `--output DIR` | Output directory for ISO files | `--output ~/iso/` |
| `--name NAME` | Custom ISO name (no .iso) | `--name my-arch` |
| `--help`, `-h` | Show help message | `--help` |

#### CLI Examples

Build 256GB version from local directory:
```bash
./build-iso.sh --cli --local /path/to/repo --version 256gb --output ~/iso/
```

Build both versions from GitHub:
```bash
./build-iso.sh --cli --github https://github.com/TZK-KG/TZK-KG.github.io \
               --version both --output ~/iso-builds/
```

Build with custom name:
```bash
./build-iso.sh --cli --local . --version 32gb \
               --output ~/isos/ --name custom-arch-32gb
```

Build from parent directory:
```bash
cd /home/runner/work/TZK-KG.github.io/TZK-KG.github.io/iso-builder
./build-iso.sh --cli --local .. --version both --output ~/output/
```

## Directory Structure

```
iso-builder/
├── build-iso.sh          # Main build script
├── README.md             # This documentation
└── templates/
    └── customize.sh      # Custom ISO hooks
```

### File Descriptions

- **build-iso.sh** - Main script with GUI and CLI support
- **templates/customize.sh** - Customization hooks executed during ISO build
- **README.md** - Comprehensive documentation

## Build Process

The ISO builder follows these steps:

1. **Dependency Check** - Verifies all required packages are installed
2. **Disk Space Check** - Ensures sufficient space for build
3. **Source Preparation** - Downloads or validates source files
4. **Profile Setup** - Creates archiso profiles with installation scripts
5. **ISO Building** - Uses mkarchiso to create bootable ISO
6. **Finalization** - Renames and moves ISO to output directory
7. **Cleanup** - Removes temporary build files

## Output

### ISO Files

Built ISO files are placed in the specified output directory with the naming format:
```
<iso-name>-<version>.iso
```

Examples:
- `archlinux-custom-256gb.iso`
- `archlinux-custom-32gb.iso`
- `my-custom-arch-256gb.iso`

### Log Files

Build logs are saved in `/tmp/` with the format:
```
/tmp/iso-builder-<pid>.log
```

These logs contain:
- Detailed build steps
- Dependency checks
- Error messages
- Timing information

## Installed ISO Contents

The built ISOs contain:
- Base Arch Linux live environment
- Installation scripts in `/root/arch-installer/` or `/root/arch-installer-32gb/`
- Custom welcome message
- Auto-start hints in bash profile

### Using the Built ISO

1. **Write to USB** (replace /dev/sdX with your USB device):
   ```bash
   sudo dd if=archlinux-custom-256gb.iso of=/dev/sdX bs=4M status=progress oflag=sync
   ```

2. **Boot from USB** - Configure BIOS/UEFI to boot from USB

3. **Run Installer**:
   ```bash
   cd /root/arch-installer
   ./arch-install.sh
   ```

## Customization

### Modifying ISO Hooks

Edit `templates/customize.sh` to customize the ISO:

```bash
vim templates/customize.sh
```

You can:
- Add custom packages
- Configure system settings
- Add files or scripts
- Set up auto-start behaviors
- Modify the welcome message

### Adjusting ISO Name Defaults

Edit the `build-iso.sh` script to change default ISO names:

```bash
ISO_NAME="${ISO_NAME:-my-custom-default-name}"
```

### Adding Custom Packages

Modify the archiso profile setup in `build-iso.sh` to include additional packages in the ISO.

## Troubleshooting

### Common Issues

#### Issue: "System is not running Arch Linux"
**Solution**: This script requires Arch Linux or an Arch-based distribution. Consider using a VM or Arch Linux live environment.

#### Issue: "Missing dependencies"
**Solution**: Run with sudo to allow automatic installation:
```bash
sudo ./build-iso.sh
```
Or manually install:
```bash
sudo pacman -S archiso git zenity
```

#### Issue: "Insufficient disk space"
**Solution**: Free up space in `/tmp`:
```bash
sudo rm -rf /tmp/archiso-build-*
```
Or mount a larger temporary directory:
```bash
sudo mount -o bind /home/username/tmp /tmp
```

#### Issue: "Failed to build ISO"
**Solution**: Check the log file for detailed error messages:
```bash
cat /tmp/iso-builder-*.log
```

Common causes:
- Insufficient permissions (use sudo)
- Missing or corrupted source files
- Network issues (for GitHub cloning)
- Disk space problems

#### Issue: "No GUI toolkit found"
**Solution**: Install zenity or dialog:
```bash
sudo pacman -S zenity    # For GTK GUI
# or
sudo pacman -S dialog    # For TUI
```
Or use CLI mode:
```bash
./build-iso.sh --cli ...
```

### Debug Mode

For detailed debugging, check the log file:
```bash
tail -f /tmp/iso-builder-*.log
```

### Manual Build

If the script fails, you can build manually:

```bash
# Copy archiso profile
cp -r /usr/share/archiso/configs/releng /tmp/myprofile

# Add installation scripts
mkdir -p /tmp/myprofile/airootfs/root/arch-installer
cp -r /path/to/arch-installer/* /tmp/myprofile/airootfs/root/arch-installer/

# Build ISO
sudo mkarchiso -v -w /tmp/work -o ~/output /tmp/myprofile
```

## Security Considerations

1. **Root Access** - ISO building requires root privileges via sudo
2. **Source Validation** - Always verify GitHub URLs before cloning
3. **ISO Integrity** - Verify ISO checksums before deployment
4. **Clean Builds** - Temporary files are cleaned up automatically

## Performance Tips

1. **Use Local Sources** - Faster than cloning from GitHub
2. **Build on Fast Storage** - Use SSD for /tmp if possible
3. **Sufficient RAM** - At least 4GB RAM recommended
4. **Single Version** - Build one version at a time for faster builds

## Examples

### Example 1: Quick Local Build
```bash
# Clone repository
git clone https://github.com/TZK-KG/TZK-KG.github.io.git
cd TZK-KG.github.io/iso-builder

# Build 256GB version with GUI
./build-iso.sh
# Select "Local Files/Directory"
# Browse to parent directory (../)
# Select "256GB USB Version"
# Choose output directory
# Confirm and build
```

### Example 2: Automated CI/CD Build
```bash
#!/bin/bash
# Automated build script for CI/CD

cd iso-builder

./build-iso.sh --cli \
    --local .. \
    --version both \
    --output /output/isos \
    --name archlinux-auto-$(date +%Y%m%d)

# Upload ISOs
# rsync -av /output/isos/ user@server:/path/to/isos/
```

### Example 3: Build from Fresh Clone
```bash
# Download and build in one go
cd /tmp
git clone https://github.com/TZK-KG/TZK-KG.github.io.git
cd TZK-KG.github.io/iso-builder

sudo ./build-iso.sh --cli \
    --local .. \
    --version 256gb \
    --output ~/my-isos/
```

## Version Selection Guide

### 256GB Version
- **Target**: 256GB+ USB drives
- **Features**: Full development environment
- **Size**: ~20-30GB installed
- **Use Case**: Complete development workstation
- **Source**: `arch-installer/`

### 32GB Version  
- **Target**: 32GB USB drives
- **Features**: Minimal, lightweight system
- **Size**: ~8-10GB installed
- **Use Case**: Portable, lightweight system
- **Source**: `arch-installer-32gb/`

### Both Versions
- Builds both ISOs sequentially
- Requires more time and disk space
- Useful for maintaining both variants

## Contributing

Contributions are welcome! Areas for improvement:
- Additional GUI toolkit support
- Parallel ISO building
- ISO compression options
- Checksum generation
- Network installation support

## References

- [Arch Linux Installation Guide](https://wiki.archlinux.org/title/Installation_guide)
- [Archiso Documentation](https://wiki.archlinux.org/title/Archiso)
- [Creating Arch Linux ISO](https://wiki.archlinux.org/title/Archiso#Configure_the_profile)

## License

This script is provided as-is for educational and personal use.

## Support

For issues or questions:
1. Check this README
2. Review log files in `/tmp/iso-builder-*.log`
3. Check [Arch Linux Wiki](https://wiki.archlinux.org/)
4. Open an issue on GitHub

---

**Last Updated**: December 2024  
**Version**: 1.0.0  
**Maintainer**: TZK-KG
