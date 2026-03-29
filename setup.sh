#!/usr/bin/env bash
set -e

# ─────────────────────────────────────────────────────────────────────────────
# LaTeX Manager Setup Script
# ─────────────────────────────────────────────────────────────────────────────
# Installs dependencies, builds the TUI, and configures the system.
# Supports macOS (Homebrew) and Linux (apt/pacman).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS=$(uname -s)
ARCH=$(uname -m)

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}➜${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_section() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ─────────────────────────────────────────────────────────────────────────────
# Dependency Installation
# ─────────────────────────────────────────────────────────────────────────────

install_dependencies_macos() {
    print_status "Installing dependencies via Homebrew..."

    # Check if Homebrew is installed
    if ! command_exists brew; then
        print_error "Homebrew not found. Install from https://brew.sh"
        return 1
    fi

    local to_install=()

    # Rust + Cargo
    if ! command_exists cargo; then
        to_install+=("rust")
    fi

    # Python3 + pyfiglet (build-time for ASCII art)
    if ! command_exists python3; then
        to_install+=("python3")
    fi

    # Neovim (for editing LaTeX)
    if ! command_exists nvim; then
        to_install+=("neovim")
    fi

    # latexmk (LaTeX compilation)
    if ! command_exists latexmk; then
        print_status "Note: latexmk requires MacTeX or BasicTeX. You can install it with:"
        echo "  brew install --cask mactex          # Full (5 GB)"
        echo "  brew install --cask basictex        # Minimal (100 MB)"
        echo ""
        print_warning "Skipping latexmk check (requires MacTeX/BasicTeX)"
    fi

    # rsync (template copying)
    if ! command_exists rsync; then
        to_install+=("rsync")
    fi

    # figlet (ASCII art header - optional but nice)
    if ! command_exists figlet; then
        print_warning "figlet not found (optional, for better output). Install with: brew install figlet"
    fi

    if [ ${#to_install[@]} -gt 0 ]; then
        print_status "Installing: ${to_install[*]}"
        brew install "${to_install[@]}" || true
    fi

    # Install pyfiglet via pip
    if ! python3 -c "import pyfiglet" 2>/dev/null; then
        print_status "Installing pyfiglet..."
        if command_exists pip3; then
            pip3 install pyfiglet
        else
            python3 -m pip install pyfiglet
        fi
    fi

    print_success "Dependencies installed"
}

install_dependencies_linux() {
    print_status "Installing dependencies..."

    # Detect Linux distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="$ID"
    else
        DISTRO="unknown"
    fi

    local to_install=()

    case "$DISTRO" in
        ubuntu|debian)
            # Rust + Cargo
            if ! command_exists cargo; then
                to_install+=("cargo" "rustc")
            fi

            # Python3 + pyfiglet
            if ! command_exists python3; then
                to_install+=("python3" "python3-pip")
            fi

            # Neovim
            if ! command_exists nvim; then
                to_install+=("neovim")
            fi

            # LaTeX
            if ! command_exists latexmk; then
                to_install+=("texlive-full" "latexmk")
            fi

            # rsync
            if ! command_exists rsync; then
                to_install+=("rsync")
            fi

            # figlet
            if ! command_exists figlet; then
                to_install+=("figlet")
            fi

            if [ ${#to_install[@]} -gt 0 ]; then
                print_status "Running: sudo apt update && sudo apt install -y ${to_install[*]}"
                sudo apt update
                sudo apt install -y "${to_install[@]}" || true
            fi
            ;;

        arch)
            if ! command_exists cargo; then
                to_install+=("rustup")
            fi

            if ! command_exists python3; then
                to_install+=("python")
            fi

            if ! command_exists nvim; then
                to_install+=("neovim")
            fi

            if ! command_exists latexmk; then
                to_install+=("texlive-most")
            fi

            if ! command_exists rsync; then
                to_install+=("rsync")
            fi

            if ! command_exists figlet; then
                to_install+=("figlet")
            fi

            if [ ${#to_install[@]} -gt 0 ]; then
                print_status "Running: sudo pacman -S ${to_install[*]}"
                sudo pacman -S --noconfirm "${to_install[@]}" || true
            fi
            ;;

        *)
            print_warning "Unknown Linux distribution: $DISTRO"
            print_status "Please install manually: rust, python3, neovim, latexmk, rsync, figlet"
            return 1
            ;;
    esac

    # Install pyfiglet via pip
    if ! python3 -c "import pyfiglet" 2>/dev/null; then
        print_status "Installing pyfiglet..."
        if command_exists pip3; then
            pip3 install --user pyfiglet
        else
            python3 -m pip install --user pyfiglet
        fi
    fi

    print_success "Dependencies installed"
}

# ─────────────────────────────────────────────────────────────────────────────
# Build TUI
# ─────────────────────────────────────────────────────────────────────────────

build_tui() {
    print_section "Building the TUI"

    if ! command_exists cargo; then
        print_error "Rust/Cargo not found. Please install from https://rustup.rs"
        return 1
    fi

    cd "$SCRIPT_DIR/tui"

    print_status "Running: cargo build --release"
    cargo build --release

    # Copy binary to tui/ directory for easier access
    cp target/release/tui tui

    # Code signing on macOS
    if [ "$OS" = "Darwin" ]; then
        print_status "Code signing binary (macOS)..."
        codesign --force --deep --sign - tui || print_warning "Code signing failed (non-critical)"
    fi

    print_success "TUI built successfully: $SCRIPT_DIR/tui/tui"
}

# ─────────────────────────────────────────────────────────────────────────────
# Setup symlink
# ─────────────────────────────────────────────────────────────────────────────

setup_symlink() {
    print_section "Setting up 'lx' command"

    local target_dir="/usr/local/bin"
    local symlink_path="$target_dir/lx"
    local binary_path="$SCRIPT_DIR/tui/tui"

    # Check if /usr/local/bin exists; if not, try alternatives
    if [ ! -d "$target_dir" ]; then
        target_dir="$HOME/.local/bin"
        symlink_path="$target_dir/lx"
        mkdir -p "$target_dir"
        print_warning "/usr/local/bin not writable, using $target_dir instead"
    fi

    # Remove existing symlink if it points to old location
    if [ -L "$symlink_path" ]; then
        rm "$symlink_path"
    fi

    # Create symlink
    ln -sf "$binary_path" "$symlink_path"

    if [ -L "$symlink_path" ]; then
        print_success "Symlink created: $symlink_path -> $binary_path"

        # Ensure ~/.local/bin is in PATH on Linux
        if [ "$OS" != "Darwin" ] && [[ ":$PATH:" != *":$target_dir:"* ]]; then
            print_warning "Add to ~/.bashrc or ~/.zshrc to ensure 'lx' is in PATH:"
            echo "  export PATH=\"$target_dir:\$PATH\""
        fi
    else
        print_error "Failed to create symlink"
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Setup PDF viewer alias
# ─────────────────────────────────────────────────────────────────────────────

setup_pdf_viewer() {
    print_section "Setting up PDF viewer"

    local shell_rc=""
    if [ -f "$HOME/.zshrc" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        shell_rc="$HOME/.bashrc"
    fi

    if [ -z "$shell_rc" ]; then
        print_warning "Could not find ~/.zshrc or ~/.bashrc"
        return 0
    fi

    # Check if tdf alias already exists
    if grep -q "alias tdf=" "$shell_rc"; then
        print_status "tdf alias already configured in $shell_rc"
        return 0
    fi

    # Suggest appropriate viewer based on OS
    local pdf_viewer_cmd=""
    if [ "$OS" = "Darwin" ]; then
        pdf_viewer_cmd="open -a Preview"
    else
        pdf_viewer_cmd="xdg-open"
    fi

    print_status "Add this to $shell_rc to set up the 'tdf' PDF viewer alias:"
    echo "  alias tdf=\"$pdf_viewer_cmd\""
    echo ""

    # Optionally add it
    read -p "Add this alias now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "alias tdf=\"$pdf_viewer_cmd\"" >> "$shell_rc"
        print_success "Alias added to $shell_rc"
        print_status "Run: source $shell_rc"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Setup workspace root in config (optional)
# ─────────────────────────────────────────────────────────────────────────────

setup_workspace_config() {
    print_section "Optional: Configure workspace root"

    local config_file="$SCRIPT_DIR/tui/tui.conf"

    # Check if workspace_root is already set
    if grep -q "^workspace_root" "$config_file"; then
        print_status "workspace_root already configured in tui.conf"
        return 0
    fi

    print_status "The TUI auto-detects workspace root by looking for templates/"
    print_status "You can explicitly set it in tui.conf if needed:"
    echo "  workspace_root = $SCRIPT_DIR"
    echo ""

    read -p "Set workspace_root in tui.conf now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Add workspace_root after the initial comments
        {
            head -n 13 "$config_file"
            echo "workspace_root = $SCRIPT_DIR"
            tail -n +14 "$config_file"
        } > "$config_file.tmp"
        mv "$config_file.tmp" "$config_file"
        print_success "workspace_root set to $SCRIPT_DIR"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Verify LaTeX distribution
# ─────────────────────────────────────────────────────────────────────────────

verify_latex() {
    print_section "Verifying LaTeX installation"

    if command_exists latexmk; then
        print_success "latexmk found"
        return 0
    fi

    print_warning "latexmk not found"
    if [ "$OS" = "Darwin" ]; then
        echo "Install MacTeX or BasicTeX:"
        echo "  brew install --cask mactex          # Full (5 GB)"
        echo "  brew install --cask basictex        # Minimal (100 MB)"
        echo "  sudo tlmgr update --self"
        echo "  sudo tlmgr install latexmk"
    else
        echo "Install with your package manager:"
        echo "  Debian/Ubuntu: sudo apt install texlive-full latexmk"
        echo "  Arch: sudo pacman -S texlive-most"
    fi
    return 1
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

main() {
    clear
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║        LaTeX Manager - Setup & Configuration           ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    print_status "Detected OS: $OS ($ARCH)"
    print_status "Project directory: $SCRIPT_DIR"
    echo ""

    # Step 1: Install dependencies
    print_section "Step 1: Installing Dependencies"
    if [ "$OS" = "Darwin" ]; then
        install_dependencies_macos || exit 1
    else
        install_dependencies_linux || exit 1
    fi

    # Step 2: Build the TUI
    build_tui || exit 1

    # Step 3: Setup symlink
    setup_symlink || print_warning "Failed to setup symlink"

    # Step 4: Setup PDF viewer
    setup_pdf_viewer

    # Step 5: Setup workspace config (optional)
    setup_workspace_config

    # Step 6: Verify LaTeX
    verify_latex || print_warning "LaTeX not fully installed yet"

    # Final summary
    print_section "Setup Complete!"
    echo ""
    echo -e "You can now run the TUI with:"
    echo -e "  ${GREEN}lx${NC}                 (if symlink is in PATH)"
    echo -e "  ${GREEN}$SCRIPT_DIR/tui/tui${NC}  (direct path)"
    echo ""
    echo -e "To start using it:"
    echo -e "  ${GREEN}cd $SCRIPT_DIR${NC}"
    echo -e "  ${GREEN}lx${NC}"
    echo ""
    echo "For more information, see README.md and INSTALL.md"
    echo ""
}

main "$@"
