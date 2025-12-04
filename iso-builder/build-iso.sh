#!/usr/bin/env bash
# Arch Linux ISO Builder with GUI
# Creates bootable Arch Linux ISOs from installation scripts
# Supports both interactive GUI and CLI modes

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
WORK_DIR="/tmp/archiso-build-$$"
LOG_FILE="/tmp/iso-builder-$$.log"

# GUI toolkit detection
GUI_TOOL=""

# User configuration
SOURCE_TYPE=""       # "local" or "github"
SOURCE_PATH=""       # Local path or GitHub URL
VERSION=""           # "256gb", "32gb", or "both"
OUTPUT_DIR=""        # Output directory for ISO
ISO_NAME=""          # Custom ISO name
CLI_MODE=false       # CLI mode flag

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*" | tee -a "$LOG_FILE"
}

# ==============================================================================
# GUI DETECTION
# ==============================================================================

detect_gui_tool() {
    if command -v zenity &> /dev/null; then
        GUI_TOOL="zenity"
        info "Using zenity for GUI dialogs"
        return 0
    elif command -v dialog &> /dev/null; then
        GUI_TOOL="dialog"
        info "Using dialog for TUI dialogs"
        return 0
    else
        warning "No GUI toolkit found. Please install zenity or dialog."
        return 1
    fi
}

# ==============================================================================
# GUI FUNCTIONS
# ==============================================================================

show_info_dialog() {
    local title="$1"
    local message="$2"
    
    if [[ "$GUI_TOOL" == "zenity" ]]; then
        zenity --info --title="$title" --text="$message" --width=400 2>/dev/null || true
    elif [[ "$GUI_TOOL" == "dialog" ]]; then
        dialog --title "$title" --msgbox "$message" 10 60
        clear
    else
        echo "$message"
    fi
}

show_error_dialog() {
    local title="$1"
    local message="$2"
    
    if [[ "$GUI_TOOL" == "zenity" ]]; then
        zenity --error --title="$title" --text="$message" --width=400 2>/dev/null || true
    elif [[ "$GUI_TOOL" == "dialog" ]]; then
        dialog --title "$title" --msgbox "$message" 10 60
        clear
    else
        echo "ERROR: $message"
    fi
}

show_question_dialog() {
    local title="$1"
    local message="$2"
    
    if [[ "$GUI_TOOL" == "zenity" ]]; then
        zenity --question --title="$title" --text="$message" --width=400 2>/dev/null
        return $?
    elif [[ "$GUI_TOOL" == "dialog" ]]; then
        dialog --title "$title" --yesno "$message" 10 60
        local result=$?
        clear
        return $result
    else
        read -p "$message (y/n): " response
        [[ "$response" =~ ^[Yy]$ ]]
    fi
}

show_text_input_dialog() {
    local title="$1"
    local message="$2"
    local default="${3:-}"
    
    if [[ "$GUI_TOOL" == "zenity" ]]; then
        zenity --entry --title="$title" --text="$message" --entry-text="$default" --width=400 2>/dev/null
    elif [[ "$GUI_TOOL" == "dialog" ]]; then
        local result=$(dialog --title "$title" --inputbox "$message" 10 60 "$default" 3>&1 1>&2 2>&3)
        clear
        echo "$result"
    else
        read -p "$message: " -i "$default" -e input
        echo "$input"
    fi
}

show_file_dialog() {
    local title="$1"
    
    if [[ "$GUI_TOOL" == "zenity" ]]; then
        zenity --file-selection --directory --title="$title" --width=600 2>/dev/null
    elif [[ "$GUI_TOOL" == "dialog" ]]; then
        local result=$(dialog --title "$title" --dselect "$HOME/" 20 60 3>&1 1>&2 2>&3)
        clear
        echo "$result"
    else
        read -p "Enter directory path: " -e path
        echo "$path"
    fi
}

show_radio_list_dialog() {
    local title="$1"
    local message="$2"
    shift 2
    local options=("$@")
    
    if [[ "$GUI_TOOL" == "zenity" ]]; then
        local zenity_opts=()
        for i in "${!options[@]}"; do
            if [[ $i -eq 0 ]]; then
                zenity_opts+=("TRUE" "${options[$i]}")
            else
                zenity_opts+=("FALSE" "${options[$i]}")
            fi
        done
        zenity --list --radiolist --title="$title" --text="$message" \
               --column="" --column="Option" "${zenity_opts[@]}" --width=400 --height=300 2>/dev/null
    elif [[ "$GUI_TOOL" == "dialog" ]]; then
        local dialog_opts=()
        for i in "${!options[@]}"; do
            local tag=$((i+1))
            if [[ $i -eq 0 ]]; then
                dialog_opts+=("$tag" "${options[$i]}" "on")
            else
                dialog_opts+=("$tag" "${options[$i]}" "off")
            fi
        done
        local result=$(dialog --title "$title" --radiolist "$message" 15 60 ${#options[@]} "${dialog_opts[@]}" 3>&1 1>&2 2>&3)
        clear
        if [[ -n "$result" ]]; then
            echo "${options[$((result-1))]}"
        fi
    else
        echo "$message"
        for i in "${!options[@]}"; do
            echo "$((i+1)). ${options[$i]}"
        done
        read -p "Select option (1-${#options[@]}): " choice
        echo "${options[$((choice-1))]}"
    fi
}

show_progress_dialog() {
    local title="$1"
    local message="$2"
    
    if [[ "$GUI_TOOL" == "zenity" ]]; then
        zenity --progress --title="$title" --text="$message" --pulsate --auto-close --no-cancel --width=400 2>/dev/null || true
    elif [[ "$GUI_TOOL" == "dialog" ]]; then
        # Dialog doesn't support pulsate progress, use gauge with percentage
        (
            local i=0
            while [[ $i -le 100 ]]; do
                echo $i
                sleep 0.1
                i=$((i + 1))
            done
        ) | dialog --title "$title" --gauge "$message" 10 60 0
        clear
    fi
}

# ==============================================================================
# DEPENDENCY CHECKING
# ==============================================================================

check_dependencies() {
    local missing_deps=()
    local all_deps=("archiso" "git" "mkarchiso" "pacman")
    
    info "Checking dependencies..."
    
    for dep in "${all_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    # Check for sudo/root
    if [[ $EUID -ne 0 ]] && ! command -v sudo &> /dev/null; then
        missing_deps+=("sudo")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        local msg="Missing dependencies: ${missing_deps[*]}\n\nWould you like to install them?"
        
        if [[ "$CLI_MODE" == true ]]; then
            error "Missing dependencies: ${missing_deps[*]}"
            error "Please install them using: pacman -S ${missing_deps[*]}"
            return 1
        fi
        
        if show_question_dialog "Missing Dependencies" "$msg"; then
            info "Installing dependencies..."
            if [[ $EUID -eq 0 ]]; then
                pacman -Sy --needed --noconfirm "${missing_deps[@]}" || {
                    show_error_dialog "Installation Failed" "Failed to install dependencies"
                    return 1
                }
            else
                sudo pacman -Sy --needed --noconfirm "${missing_deps[@]}" || {
                    show_error_dialog "Installation Failed" "Failed to install dependencies"
                    return 1
                }
            fi
            success "Dependencies installed successfully"
        else
            show_error_dialog "Cannot Continue" "Required dependencies are not installed"
            return 1
        fi
    fi
    
    success "All dependencies are available"
    return 0
}

# ==============================================================================
# DISK SPACE CHECKING
# ==============================================================================

check_disk_space() {
    local required_space=4000000  # 4GB in KB
    local available_space
    
    available_space=$(df /tmp | awk 'NR==2 {print $4}')
    
    if [[ $available_space -lt $required_space ]]; then
        local msg="Insufficient disk space in /tmp\nRequired: 4GB\nAvailable: $((available_space / 1024 / 1024))GB"
        show_error_dialog "Disk Space Error" "$msg"
        return 1
    fi
    
    return 0
}

# ==============================================================================
# SOURCE SELECTION
# ==============================================================================

select_source_gui() {
    info "Selecting source..."
    
    local source_type=$(show_radio_list_dialog "Source Selection" \
        "Choose the source for installation scripts:" \
        "Local Files/Directory" "GitHub Repository URL")
    
    if [[ -z "$source_type" ]]; then
        show_error_dialog "Error" "Source selection cancelled"
        return 1
    fi
    
    if [[ "$source_type" == "Local Files/Directory" ]]; then
        SOURCE_TYPE="local"
        SOURCE_PATH=$(show_file_dialog "Select Source Directory")
        
        if [[ -z "$SOURCE_PATH" || ! -d "$SOURCE_PATH" ]]; then
            show_error_dialog "Error" "Invalid directory selected"
            return 1
        fi
        
        info "Selected local directory: $SOURCE_PATH"
    else
        SOURCE_TYPE="github"
        SOURCE_PATH=$(show_text_input_dialog "GitHub URL" \
            "Enter GitHub repository URL:" \
            "https://github.com/TZK-KG/TZK-KG.github.io")
        
        if [[ -z "$SOURCE_PATH" ]]; then
            show_error_dialog "Error" "GitHub URL is required"
            return 1
        fi
        
        if ! [[ "$SOURCE_PATH" =~ ^https?://github\.com/.+ ]]; then
            show_error_dialog "Error" "Invalid GitHub URL format"
            return 1
        fi
        
        info "Selected GitHub repository: $SOURCE_PATH"
    fi
    
    return 0
}

# ==============================================================================
# VERSION SELECTION
# ==============================================================================

select_version_gui() {
    info "Selecting version..."
    
    VERSION=$(show_radio_list_dialog "Version Selection" \
        "Select which installer version to build:" \
        "256GB USB Version (arch-installer/)" \
        "32GB USB Version (arch-installer-32gb/)" \
        "Both Versions")
    
    if [[ -z "$VERSION" ]]; then
        show_error_dialog "Error" "Version selection cancelled"
        return 1
    fi
    
    case "$VERSION" in
        "256GB USB Version (arch-installer/)")
            VERSION="256gb"
            ;;
        "32GB USB Version (arch-installer-32gb/)")
            VERSION="32gb"
            ;;
        "Both Versions")
            VERSION="both"
            ;;
    esac
    
    info "Selected version: $VERSION"
    return 0
}

# ==============================================================================
# OUTPUT CONFIGURATION
# ==============================================================================

configure_output_gui() {
    info "Configuring output..."
    
    OUTPUT_DIR=$(show_file_dialog "Select Output Directory")
    
    if [[ -z "$OUTPUT_DIR" ]]; then
        OUTPUT_DIR="$HOME/iso-output"
        warning "No directory selected, using default: $OUTPUT_DIR"
    fi
    
    mkdir -p "$OUTPUT_DIR" || {
        show_error_dialog "Error" "Failed to create output directory: $OUTPUT_DIR"
        return 1
    }
    
    info "Output directory: $OUTPUT_DIR"
    
    # Ask for custom ISO name
    ISO_NAME=$(show_text_input_dialog "ISO Name" \
        "Enter custom ISO name (without .iso extension):" \
        "archlinux-custom")
    
    if [[ -z "$ISO_NAME" ]]; then
        ISO_NAME="archlinux-custom"
        warning "No name provided, using default: $ISO_NAME"
    fi
    
    info "ISO name: $ISO_NAME"
    return 0
}

# ==============================================================================
# SOURCE PREPARATION
# ==============================================================================

prepare_source() {
    info "Preparing source..."
    
    mkdir -p "$WORK_DIR"
    
    if [[ "$SOURCE_TYPE" == "github" ]]; then
        info "Cloning GitHub repository..."
        
        if ! git clone "$SOURCE_PATH" "$WORK_DIR/source" >> "$LOG_FILE" 2>&1; then
            error "Failed to clone repository: $SOURCE_PATH"
            return 1
        fi
        
        SOURCE_PATH="$WORK_DIR/source"
        success "Repository cloned successfully"
    fi
    
    # Verify required directories exist
    local required_dirs=()
    
    if [[ "$VERSION" == "256gb" || "$VERSION" == "both" ]]; then
        required_dirs+=("$SOURCE_PATH/arch-installer")
    fi
    
    if [[ "$VERSION" == "32gb" || "$VERSION" == "both" ]]; then
        required_dirs+=("$SOURCE_PATH/arch-installer-32gb")
    fi
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            error "Required directory not found: $dir"
            return 1
        fi
    done
    
    success "Source prepared successfully"
    return 0
}

# ==============================================================================
# ARCHISO PROFILE SETUP
# ==============================================================================

setup_archiso_profile() {
    local version_name="$1"
    local installer_dir="$2"
    local profile_dir="$WORK_DIR/profile-$version_name"
    
    info "Setting up archiso profile for $version_name..."
    
    # Copy base archiso profile
    cp -r /usr/share/archiso/configs/releng "$profile_dir" || {
        error "Failed to copy archiso profile"
        return 1
    }
    
    # Create airootfs/root directory
    mkdir -p "$profile_dir/airootfs/root/arch-installer"
    
    # Copy installation scripts
    cp -r "$installer_dir"/* "$profile_dir/airootfs/root/arch-installer/" || {
        error "Failed to copy installation scripts"
        return 1
    }
    
    # Make scripts executable
    chmod +x "$profile_dir/airootfs/root/arch-installer"/*.sh 2>/dev/null || true
    
    # Copy customize script if exists
    if [[ -f "$SCRIPT_DIR/templates/customize.sh" ]]; then
        cp "$SCRIPT_DIR/templates/customize.sh" "$profile_dir/airootfs/root/customize.sh"
        chmod +x "$profile_dir/airootfs/root/customize.sh"
    fi
    
    # Create auto-start script in profile
    cat > "$profile_dir/airootfs/root/.automated_script.sh" << 'EOF'
#!/bin/bash
if [ -f /root/arch-installer/arch-install.sh ]; then
    cd /root/arch-installer
    echo "Installation scripts are available in /root/arch-installer/"
    echo "Run: ./arch-install.sh to start the installation"
fi
EOF
    chmod +x "$profile_dir/airootfs/root/.automated_script.sh"
    
    success "Archiso profile setup complete for $version_name"
    echo "$profile_dir"
    return 0
}

# ==============================================================================
# ISO BUILDING
# ==============================================================================

build_iso() {
    local version_name="$1"
    local profile_dir="$2"
    local output_name="${ISO_NAME}-${version_name}"
    
    info "Building ISO for $version_name..."
    
    # Build the ISO
    local build_cmd="mkarchiso -v -w $WORK_DIR/work-$version_name -o $OUTPUT_DIR $profile_dir"
    
    if [[ $EUID -ne 0 ]]; then
        build_cmd="sudo $build_cmd"
    fi
    
    info "Running: $build_cmd"
    
    if ! $build_cmd >> "$LOG_FILE" 2>&1; then
        error "Failed to build ISO for $version_name"
        return 1
    fi
    
    # Find the generated ISO and rename it
    local generated_iso=$(find "$OUTPUT_DIR" -name "archlinux-*.iso" -type f -printf '%T+ %p\n' | sort -r | head -n1 | cut -d' ' -f2-)
    
    if [[ -n "$generated_iso" && -f "$generated_iso" ]]; then
        local new_name="$OUTPUT_DIR/${output_name}.iso"
        mv "$generated_iso" "$new_name" || {
            warning "Failed to rename ISO, keeping original name"
            new_name="$generated_iso"
        }
        success "ISO built successfully: $new_name"
        echo "$new_name"
    else
        error "ISO file not found after build"
        return 1
    fi
    
    return 0
}

# ==============================================================================
# MAIN BUILD PROCESS
# ==============================================================================

run_build_process() {
    info "Starting build process..."
    
    local built_isos=()
    
    # Prepare source
    if ! prepare_source; then
        show_error_dialog "Build Failed" "Failed to prepare source. Check log: $LOG_FILE"
        return 1
    fi
    
    # Build based on version selection
    if [[ "$VERSION" == "256gb" || "$VERSION" == "both" ]]; then
        local installer_dir="$SOURCE_PATH/arch-installer"
        local profile_dir=$(setup_archiso_profile "256gb" "$installer_dir") || {
            show_error_dialog "Build Failed" "Failed to setup archiso profile for 256GB version"
            return 1
        }
        
        local iso_path=$(build_iso "256gb" "$profile_dir") || {
            show_error_dialog "Build Failed" "Failed to build ISO for 256GB version. Check log: $LOG_FILE"
            return 1
        }
        
        built_isos+=("$iso_path")
    fi
    
    if [[ "$VERSION" == "32gb" || "$VERSION" == "both" ]]; then
        local installer_dir="$SOURCE_PATH/arch-installer-32gb"
        local profile_dir=$(setup_archiso_profile "32gb" "$installer_dir") || {
            show_error_dialog "Build Failed" "Failed to setup archiso profile for 32GB version"
            return 1
        }
        
        local iso_path=$(build_iso "32gb" "$profile_dir") || {
            show_error_dialog "Build Failed" "Failed to build ISO for 32GB version. Check log: $LOG_FILE"
            return 1
        }
        
        built_isos+=("$iso_path")
    fi
    
    # Show success message
    local success_msg="ISO build completed successfully!\n\nBuilt ISOs:\n"
    for iso in "${built_isos[@]}"; do
        success_msg+="• $iso\n"
    done
    success_msg+="\nLog file: $LOG_FILE"
    
    show_info_dialog "Build Complete" "$success_msg"
    success "Build process completed successfully"
    
    return 0
}

# ==============================================================================
# CLEANUP
# ==============================================================================

cleanup() {
    if [[ -d "$WORK_DIR" ]]; then
        info "Cleaning up temporary files..."
        rm -rf "$WORK_DIR" 2>/dev/null || true
        success "Cleanup complete"
    fi
}

trap cleanup EXIT

# ==============================================================================
# CLI MODE
# ==============================================================================

parse_cli_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --cli)
                CLI_MODE=true
                shift
                ;;
            --source)
                SOURCE_PATH="$2"
                shift 2
                ;;
            --github)
                SOURCE_TYPE="github"
                SOURCE_PATH="$2"
                shift 2
                ;;
            --local)
                SOURCE_TYPE="local"
                SOURCE_PATH="$2"
                shift 2
                ;;
            --version)
                VERSION="$2"
                shift 2
                ;;
            --output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --name)
                ISO_NAME="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << EOF
Arch Linux ISO Builder with GUI

USAGE:
    $0 [OPTIONS]

MODES:
    GUI Mode (default):
        $0
        
    CLI Mode:
        $0 --cli --source <path|url> --version <version> --output <dir>

OPTIONS:
    --cli               Enable CLI mode (no GUI)
    --source PATH       Source directory or GitHub URL
    --github URL        GitHub repository URL (sets source type to github)
    --local PATH        Local directory path (sets source type to local)
    --version VERSION   Version to build: 256gb, 32gb, or both
    --output DIR        Output directory for ISO files
    --name NAME         Custom ISO name (without .iso extension)
    --help, -h          Show this help message

EXAMPLES:
    # GUI mode (interactive)
    $0
    
    # CLI mode with local source
    $0 --cli --local /path/to/repo --version 256gb --output ~/iso/
    
    # CLI mode with GitHub URL
    $0 --cli --github https://github.com/TZK-KG/TZK-KG.github.io --version both --output ~/iso/
    
    # CLI mode with custom name
    $0 --cli --local . --version 256gb --output ~/iso/ --name my-custom-arch

REQUIREMENTS:
    - archiso package installed
    - git (for GitHub sources)
    - zenity or dialog (for GUI mode)
    - sudo/root access for mkarchiso

EOF
}

validate_cli_args() {
    local errors=()
    
    if [[ -z "$SOURCE_PATH" ]]; then
        errors+=("Source path is required (--source, --github, or --local)")
    fi
    
    if [[ -z "$SOURCE_TYPE" ]]; then
        if [[ "$SOURCE_PATH" =~ ^https?://github\.com/.+ ]]; then
            SOURCE_TYPE="github"
        elif [[ -d "$SOURCE_PATH" ]]; then
            SOURCE_TYPE="local"
        else
            errors+=("Cannot determine source type. Use --github or --local")
        fi
    fi
    
    if [[ "$SOURCE_TYPE" == "local" && ! -d "$SOURCE_PATH" ]]; then
        errors+=("Local source directory does not exist: $SOURCE_PATH")
    fi
    
    if [[ "$SOURCE_TYPE" == "github" && ! "$SOURCE_PATH" =~ ^https?://github\.com/.+ ]]; then
        errors+=("Invalid GitHub URL format: $SOURCE_PATH")
    fi
    
    if [[ -z "$VERSION" ]]; then
        errors+=("Version is required (--version 256gb|32gb|both)")
    fi
    
    if [[ "$VERSION" != "256gb" && "$VERSION" != "32gb" && "$VERSION" != "both" ]]; then
        errors+=("Invalid version: $VERSION (must be 256gb, 32gb, or both)")
    fi
    
    if [[ -z "$OUTPUT_DIR" ]]; then
        OUTPUT_DIR="$HOME/iso-output"
        warning "No output directory specified, using default: $OUTPUT_DIR"
    fi
    
    if [[ -z "$ISO_NAME" ]]; then
        ISO_NAME="archlinux-custom"
        warning "No ISO name specified, using default: $ISO_NAME"
    fi
    
    if [[ ${#errors[@]} -gt 0 ]]; then
        for err in "${errors[@]}"; do
            error "$err"
        done
        return 1
    fi
    
    return 0
}

run_cli_mode() {
    info "Running in CLI mode"
    
    if ! validate_cli_args; then
        error "Invalid arguments"
        show_help
        return 1
    fi
    
    info "Configuration:"
    info "  Source Type: $SOURCE_TYPE"
    info "  Source Path: $SOURCE_PATH"
    info "  Version: $VERSION"
    info "  Output Dir: $OUTPUT_DIR"
    info "  ISO Name: $ISO_NAME"
    
    if ! check_dependencies; then
        return 1
    fi
    
    if ! check_disk_space; then
        return 1
    fi
    
    if ! run_build_process; then
        return 1
    fi
    
    return 0
}

# ==============================================================================
# GUI MODE
# ==============================================================================

run_gui_mode() {
    info "Running in GUI mode"
    
    if ! detect_gui_tool; then
        error "No GUI toolkit available. Install zenity or dialog, or use --cli mode"
        return 1
    fi
    
    # Welcome message
    show_info_dialog "Arch Linux ISO Builder" \
        "Welcome to the Arch Linux ISO Builder!\n\nThis tool will help you create bootable Arch Linux ISOs from installation scripts.\n\nClick OK to continue."
    
    # Check dependencies
    if ! check_dependencies; then
        return 1
    fi
    
    if ! check_disk_space; then
        return 1
    fi
    
    # Select source
    if ! select_source_gui; then
        return 1
    fi
    
    # Select version
    if ! select_version_gui; then
        return 1
    fi
    
    # Configure output
    if ! configure_output_gui; then
        return 1
    fi
    
    # Confirm and build
    local confirm_msg="Ready to build ISO with the following configuration:\n\n"
    confirm_msg+="Source: $SOURCE_TYPE - $SOURCE_PATH\n"
    confirm_msg+="Version: $VERSION\n"
    confirm_msg+="Output: $OUTPUT_DIR\n"
    confirm_msg+="ISO Name: $ISO_NAME\n\n"
    confirm_msg+="Proceed with build?"
    
    if ! show_question_dialog "Confirm Build" "$confirm_msg"; then
        show_info_dialog "Cancelled" "Build cancelled by user"
        return 0
    fi
    
    # Run build in background with progress
    (run_build_process) &
    local build_pid=$!
    
    # Show progress dialog while building
    if [[ "$GUI_TOOL" == "zenity" ]]; then
        (
            while kill -0 $build_pid 2>/dev/null; do
                echo "#Building ISO... Please wait..."
                sleep 1
            done
        ) | zenity --progress --title="Building ISO" --text="Building ISO... Please wait..." \
                    --pulsate --auto-close --no-cancel --width=400 2>/dev/null || true
    fi
    
    wait $build_pid
    return $?
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    log "========================================="
    log "Arch Linux ISO Builder Starting"
    log "========================================="
    log "Script: $0"
    log "PID: $$"
    log "User: $(whoami)"
    log "Date: $(date)"
    log ""
    
    # Parse CLI arguments
    parse_cli_args "$@"
    
    # Run appropriate mode
    if [[ "$CLI_MODE" == true ]]; then
        if ! run_cli_mode; then
            error "Build failed in CLI mode"
            exit 1
        fi
    else
        if ! run_gui_mode; then
            error "Build failed in GUI mode"
            exit 1
        fi
    fi
    
    success "ISO Builder completed successfully"
    log "Log file: $LOG_FILE"
    exit 0
}

main "$@"
