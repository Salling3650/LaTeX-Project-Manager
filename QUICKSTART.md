# Quick Start Guide

Get LaTeX Manager up and running on a new machine in minutes.

## Prerequisites

- **macOS:** Homebrew installed (get it at https://brew.sh)
- **Linux:** Your system package manager (apt, pacman, etc.)
- **Both:** ~2GB disk space for dependencies

## One-Command Setup

```bash
./setup.sh
```

This script automatically:
- ✓ Installs all dependencies (Rust, Python, Neovim, LaTeX, rsync, figlet)
- ✓ Builds the TUI binary
- ✓ Creates an `lx` symlink for easy launching
- ✓ Configures PDF viewer
- ✓ Verifies the LaTeX installation

**The setup takes about 10-15 minutes** (most of the time is Rust compilation on first build).

## What Gets Installed

### macOS (via Homebrew)
- `rust` + `cargo` — Rust compiler
- `python3` + `pyfiglet` — ASCII art generation
- `neovim` — LaTeX editor
- `rsync` — Template copying
- `figlet` — ASCII headers
- ⚠️ **Manual:** MacTeX or BasicTeX for LaTeX compilation (https://www.tug.org/mactex/)

### Linux (Debian/Ubuntu)
- `cargo`, `rustc` — Rust compiler
- `python3`, `python3-pip`, `pyfiglet` — ASCII art
- `neovim` — Editor
- `texlive-full`, `latexmk` — LaTeX
- `rsync`, `figlet` — Utilities

### Linux (Arch)
- `rustup` — Rust
- `python`, `pyfiglet` — ASCII art
- `neovim`, `texlive-most` — Editing & LaTeX
- `rsync`, `figlet` — Utilities

## After Setup

Once the setup script completes, launch the TUI:

```bash
lx
```

Or from the project directory:
```bash
cd /path/to/Latex && ./tui/tui
```

## Configuration

### PDF Viewer (one-time setup)

The setup script asks if you want to configure the PDF viewer. This adds an alias to your shell:

```bash
alias tdf="open -a Preview"  # macOS Preview
# or
alias tdf="open -a Skim"     # macOS Skim
# or
alias tdf="zathura"          # Linux
```

You can edit this later in your `~/.zshrc` or `~/.bashrc`.

### Colors & Workspace

Edit `tui/tui.conf` to customize:

```ini
# Accent color for title and menu highlight
accent_color = cyan

# Footer hint color
footer_color = dark_gray

# PDF viewer command
pdf_viewer = open -a Preview

# Workspace root (optional; auto-detected if not set)
# workspace_root = /path/to/Latex
```

**No rebuild required** — changes take effect on next launch.

## Troubleshooting

### Command `lx` not found
The symlink wasn't created with write permissions. Either:
1. Run `setup.sh` again with `sudo` (not recommended)
2. Run the TUI directly: `cd /path/to/Latex && ./tui/tui`
3. On Linux, add `~/.local/bin` to your PATH:
   ```bash
   export PATH="$HOME/.local/bin:$PATH"
   ```

### `latexmk` command not found
LaTeX isn't installed yet. On macOS, install MacTeX or BasicTeX:
```bash
brew install --cask mactex        # Full (5 GB)
# or
brew install --cask basictex      # Minimal (100 MB)
sudo tlmgr update --self
sudo tlmgr install latexmk
```

### Build fails with permission errors
Make sure the repository is writable. If cloned as root or restricted:
```bash
chmod -R u+w /path/to/Latex
```

### Script says "Homebrew not found" (macOS)
Install Homebrew first: https://brew.sh

### Neovim won't open when creating projects
Make sure `nvim` is installed and in your PATH:
```bash
which nvim
nvim --version
```

## Verify Installation

Run this to check everything:
```bash
echo "Checking dependencies..."
command -v cargo && echo "✓ Rust" || echo "✗ Rust missing"
command -v python3 && echo "✓ Python" || echo "✗ Python missing"
command -v nvim && echo "✓ Neovim" || echo "✗ Neovim missing"
command -v latexmk && echo "✓ LaTeX" || echo "✗ LaTeX missing"
command -v rsync && echo "✓ rsync" || echo "✗ rsync missing"
command -v lx && echo "✓ lx symlink" || echo "✗ lx symlink missing"
```

## Next Steps

1. **Create a blank project:** Select "Blank project" in the TUI
2. **Use a template:** Select "Template selector" and pick a template folder
3. **Open an existing project:** Select "Open project"
4. **Convert to mindmap:** Select "Convert to mindmap" (if configured)

For full documentation, see [README.md](README.md) and [.github/copilot-instructions.md](.github/copilot-instructions.md).
