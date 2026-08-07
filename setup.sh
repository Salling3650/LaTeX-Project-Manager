#!/usr/bin/env bash
set -e

# ─────────────────────────────────────────────────────────────────────────────
# LaTeX Manager Setup Script
# ─────────────────────────────────────────────────────────────────────────────
# One command, no questions asked: installs dependencies (including a working
# LaTeX distribution if you don't have one), builds the TUI, and sets up the
# 'lx' command. Supports macOS (Homebrew) and Linux (apt/pacman).
#
# Every step is best-effort: if one thing fails (no sudo, no network, an
# unknown distro), the script warns and keeps going rather than aborting —
# you always end up with as much working as could be set up, never nothing.
#
# Flags:
#   --skip-latex   Skip installing a LaTeX distribution (e.g. you already
#                  have one under a name this script doesn't detect, or you
#                  want to add it yourself later).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS=$(uname -s)
ARCH=$(uname -m)
SKIP_LATEX=0

for arg in "$@"; do
    case "$arg" in
        --skip-latex) SKIP_LATEX=1 ;;
    esac
done

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status()  { echo -e "${BLUE}➜${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error()   { echo -e "${RED}✗${NC} $1"; }
print_section() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ─────────────────────────────────────────────────────────────────────────────
# LaTeX installation — the thing most likely to be missing, and the biggest
# download, so it gets its own clearly-labelled step with its own fallback
# messaging if it fails.
# ─────────────────────────────────────────────────────────────────────────────

install_latex_macos() {
    if command_exists latexmk; then
        print_success "latexmk found"
        return 0
    fi
    if [ "$SKIP_LATEX" -eq 1 ]; then
        print_warning "Skipping LaTeX install (--skip-latex)"
        return 0
    fi

    print_status "No LaTeX found — installing BasicTeX (~100 MB)..."
    if ! brew install --cask basictex; then
        print_warning "BasicTeX install failed. Install it manually later with:"
        echo "  brew install --cask basictex"
        return 1
    fi

    # BasicTeX installs to a path that isn't on PATH in this shell session yet.
    export PATH="/Library/TeX/texbin:$PATH"

    print_status "Installing latexmk (may ask for your password)..."
    if sudo /Library/TeX/texbin/tlmgr update --self >/dev/null 2>&1 \
        && sudo /Library/TeX/texbin/tlmgr install latexmk >/dev/null 2>&1; then
        print_success "LaTeX installed"
    else
        print_warning "latexmk install via tlmgr didn't complete. Finish it yourself with:"
        echo "  sudo tlmgr update --self && sudo tlmgr install latexmk"
        return 1
    fi

    print_status "Note: BasicTeX is minimal. If a document needs a package it doesn't"
    print_status "have, the compile popup will show the missing package in red — fix"
    print_status "it with: sudo tlmgr install <package-name>"
}

install_latex_linux() {
    local distro="$1"
    if command_exists latexmk; then
        print_success "latexmk found"
        return 0
    fi
    if [ "$SKIP_LATEX" -eq 1 ]; then
        print_warning "Skipping LaTeX install (--skip-latex)"
        return 0
    fi

    case "$distro" in
        ubuntu|debian)
            # Deliberately not texlive-full (5+ GB, very slow). This set
            # covers essentially all coursework-level documents in a
            # fraction of the time; missing packages show up clearly in the
            # compile popup's error highlighting and are one `apt install`
            # or `tlmgr install` away.
            print_status "Installing LaTeX (texlive-latex-extra, ~300-500 MB)..."
            sudo apt update
            if sudo apt install -y texlive-latex-base texlive-latex-recommended \
                texlive-latex-extra texlive-fonts-recommended latexmk; then
                print_success "LaTeX installed"
            else
                print_warning "LaTeX install failed. Install it manually later with:"
                echo "  sudo apt install texlive-latex-extra latexmk"
                return 1
            fi
            ;;
        arch|archarm)
            print_status "Installing LaTeX (texlive-most, ~2 GB)..."
            if sudo pacman -S --noconfirm texlive-most texlive-latexextra latexmk 2>/dev/null \
                || sudo pacman -S --noconfirm texlive-most; then
                print_success "LaTeX installed"
            else
                print_warning "LaTeX install failed. Install it manually later with:"
                echo "  sudo pacman -S texlive-most"
                return 1
            fi
            ;;
        *)
            print_warning "Unknown distro — install LaTeX manually (needs 'latexmk' on PATH)"
            return 1
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────────────────────
# Dependency Installation
# ─────────────────────────────────────────────────────────────────────────────

install_dependencies_macos() {
    print_status "Installing dependencies via Homebrew..."

    if ! command_exists brew; then
        print_error "Homebrew not found. Install from https://brew.sh"
        return 1
    fi

    local to_install=()
    command_exists cargo   || to_install+=("rust")
    command_exists python3 || to_install+=("python3")
    command_exists nvim    || to_install+=("neovim")
    command_exists rsync   || to_install+=("rsync")
    command_exists npm     || to_install+=("node")   # for "Convert to mindmap" (markmap-cli)

    if [ ${#to_install[@]} -gt 0 ]; then
        print_status "Installing: ${to_install[*]}"
        brew install "${to_install[@]}" || print_warning "Some packages may have failed to install"
    fi

    install_latex_macos || true

    print_success "Dependencies installed"
}

install_dependencies_linux() {
    print_status "Installing dependencies..."

    local distro="unknown"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        distro="$ID"
    fi

    local to_install=()

    case "$distro" in
        ubuntu|debian)
            command_exists cargo  || to_install+=("cargo" "rustc")
            command_exists python3 || to_install+=("python3" "python3-pip")
            command_exists nvim   || to_install+=("neovim")
            command_exists rsync  || to_install+=("rsync")
            command_exists npm    || to_install+=("npm")   # for "Convert to mindmap" (markmap-cli)

            if [ ${#to_install[@]} -gt 0 ]; then
                print_status "Running: sudo apt update && sudo apt install -y ${to_install[*]}"
                sudo apt update
                sudo apt install -y "${to_install[@]}" || print_warning "Some packages may have failed to install"
            fi
            ;;

        arch|archarm)
            command_exists cargo  || to_install+=("rustup")
            command_exists python3 || to_install+=("python")
            command_exists nvim   || to_install+=("neovim")
            command_exists rsync  || to_install+=("rsync")
            command_exists npm    || to_install+=("npm")   # for "Convert to mindmap" (markmap-cli)

            if [ ${#to_install[@]} -gt 0 ]; then
                print_status "Running: sudo pacman -S ${to_install[*]}"
                sudo pacman -S --noconfirm "${to_install[@]}" || print_warning "Some packages may have failed to install"
            fi
            ;;

        *)
            print_warning "Unknown Linux distribution: $distro"
            print_status "Please install manually: rust, python3, neovim, latexmk, rsync, npm"
            return 1
            ;;
    esac

    install_latex_linux "$distro" || true

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

    cp target/release/tui tui

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

    if [ ! -w "$target_dir" ] 2>/dev/null; then
        target_dir="$HOME/.local/bin"
        symlink_path="$target_dir/lx"
        mkdir -p "$target_dir"
        print_warning "$target_dir not writable, using $HOME/.local/bin instead"
    fi

    [ -L "$symlink_path" ] && rm "$symlink_path"
    ln -sf "$binary_path" "$symlink_path"

    if [ -L "$symlink_path" ]; then
        print_success "Symlink created: $symlink_path -> $binary_path"
        if [ "$OS" != "Darwin" ] && [[ ":$PATH:" != *":$target_dir:"* ]]; then
            print_warning "Add this to ~/.bashrc or ~/.zshrc so 'lx' is on your PATH:"
            echo "  export PATH=\"$target_dir:\$PATH\""
        fi
    else
        print_error "Failed to create symlink"
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Verify LaTeX distribution
# ─────────────────────────────────────────────────────────────────────────────

verify_latex() {
    print_section "Verifying LaTeX installation"

    if command_exists latexmk; then
        print_success "latexmk found — compiling should work out of the box"
        return 0
    fi

    print_warning "latexmk still not found — compiling won't work until it's installed"
    if [ "$OS" = "Darwin" ]; then
        echo "  brew install --cask basictex && sudo tlmgr update --self && sudo tlmgr install latexmk"
        echo "  (then restart your terminal so /Library/TeX/texbin is on PATH)"
    else
        echo "  Debian/Ubuntu: sudo apt install texlive-latex-extra latexmk"
        echo "  Arch:          sudo pacman -S texlive-most"
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
    [ "$SKIP_LATEX" -eq 1 ] && print_status "LaTeX install: skipped (--skip-latex)"
    echo ""

    print_section "Step 1: Installing Dependencies"
    if [ "$OS" = "Darwin" ]; then
        install_dependencies_macos || exit 1
    else
        install_dependencies_linux || exit 1
    fi

    build_tui || exit 1
    setup_symlink || print_warning "Failed to setup symlink"
    verify_latex || true

    print_section "Setup Complete!"
    echo ""
    echo -e "Run it with:"
    echo -e "  ${GREEN}lx${NC}                 (if symlink is in PATH)"
    echo -e "  ${GREEN}$SCRIPT_DIR/tui/tui${NC}  (direct path)"
    echo ""
    echo -e "Try it now:"
    echo -e "  ${GREEN}cd $SCRIPT_DIR && lx${NC}"
    echo ""
    echo "For more information, see README.md and QUICKSTART.md"
    echo ""
}

main "$@"
