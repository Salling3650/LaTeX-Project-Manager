# Quick Start Guide

Get LaTeX Manager up and running on a new machine in minutes.

## Prerequisites

- **macOS:** Homebrew installed (get it at https://brew.sh)
- **Linux:** Your system package manager (apt, pacman, etc.)
- **Both:** ~1-2 GB disk space (mostly LaTeX, if you don't already have it)

## One-Command Setup

```bash
./setup.sh
```

No prompts, no follow-up steps. This script:
- ✓ Installs Rust, Python, Neovim, rsync, npm (all skipped if already present)
- ✓ Installs a working LaTeX distribution if `latexmk` isn't already on your PATH
- ✓ Builds the TUI binary
- ✓ Creates an `lx` symlink for easy launching
- ✓ Verifies everything actually ended up working, and tells you plainly if something didn't

**Setup takes about 5-15 minutes** depending mostly on whether LaTeX needs installing and how fast your first `cargo build --release` is.

Don't want the LaTeX download right now? `./setup.sh --skip-latex` skips just that step — everything else (creating/editing/browsing projects) still works, only compiling won't until you install LaTeX yourself later.

## What Gets Installed

### macOS (via Homebrew)
- `rust` + `cargo` — Rust compiler
- `python3` — needed only for "Convert to mindmap" (pylatexenc)
- `neovim` — LaTeX editor
- `rsync` — Template copying
- `node` (npm) — needed only for "Convert to mindmap" (markmap-cli)
- **BasicTeX** (~100 MB) — auto-installed via `brew install --cask basictex` + `tlmgr install latexmk`, only if `latexmk` isn't already found

### Linux (Debian/Ubuntu)
- `cargo`, `rustc` — Rust compiler
- `python3`, `python3-pip` — needed only for "Convert to mindmap"
- `neovim` — Editor
- `rsync` — Template copying
- `npm` — needed only for "Convert to mindmap"
- **texlive-latex-base, texlive-latex-recommended, texlive-latex-extra, texlive-fonts-recommended, latexmk** (~300-500 MB) — auto-installed only if `latexmk` isn't already found. Deliberately not `texlive-full` (5+ GB) — this covers essentially all coursework-level documents; the compile popup highlights any missing package in red if you ever do hit one.

### Linux (Arch)
- `rustup` — Rust
- `python` — needed only for "Convert to mindmap"
- `neovim` — Editing
- `rsync` — Template copying
- `npm` — needed only for "Convert to mindmap"
- **texlive-most** (~2 GB) — auto-installed only if `latexmk` isn't already found

The ASCII-art title doesn't need Python or the `figlet` CLI tool at all — it's generated at compile time by the `figlet-rs` Rust crate (a normal Cargo dependency), so `cargo build` handles it automatically with nothing extra to install.

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

### PDF viewer

Nothing to set up — the TUI auto-detects a sensible default (`open` on macOS, `xdg-open` on Linux) the first time it runs. Want a specific viewer instead (Skim, Zathura, etc.)? Set it directly in `tui/tui.conf`:

```ini
pdf_viewer = open -a Skim
```

### Colors & Workspace

Edit `tui/tui.conf` to customize:

```ini
# Accent color for title and menu highlight
accent_color = cyan

# Footer hint color
footer_color = dark_gray

# PDF viewer (optional — auto-detected if unset)
# pdf_viewer = zathura

# Workspace root (optional; auto-detected if not set)
# workspace_root = /path/to/Latex

# Extra project roots (optional, repeatable — see README.md)
# project_root = Uni:~/School/Latex/projects
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

### `latexmk` command not found after setup
`setup.sh` tries to install LaTeX automatically — if it still didn't work (no sudo access, no network, an install failure), finish it yourself:
```bash
# macOS
brew install --cask basictex
sudo tlmgr update --self && sudo tlmgr install latexmk
# then restart your terminal so /Library/TeX/texbin is on PATH

# Debian/Ubuntu
sudo apt install texlive-latex-extra latexmk

# Arch
sudo pacman -S texlive-most
```

### Compile fails with "File `xyz.sty' not found"
The compile popup shows this in red. Install the missing package:
```bash
# macOS (BasicTeX)
sudo tlmgr install xyz

# Debian/Ubuntu
sudo apt install texlive-latex-extra   # covers most common packages

# Arch
sudo pacman -S texlive-most            # already includes nearly everything
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
command -v nvim && echo "✓ Neovim" || echo "✗ Neovim missing"
command -v latexmk && echo "✓ LaTeX" || echo "✗ LaTeX missing"
command -v rsync && echo "✓ rsync" || echo "✗ rsync missing"
command -v lx && echo "✓ lx symlink" || echo "✗ lx symlink missing"
command -v npm && echo "✓ npm (mindmap)" || echo "○ npm missing (only needed for Convert to mindmap)"
```

## Next Steps

1. **Create a blank project:** Select "Blank project" in the TUI, or `lx new <name>`
2. **Use a template:** Select "Template selector" and pick a template folder
3. **Open an existing project:** Select "Open project", `lx open <query>`, or just `lx <name>`
4. **Convert to mindmap:** Select "Convert to mindmap" (needs Python + npm, installed above)
5. **Clean up old builds:** Select "Clean build folders" to reclaim space from `.build/` folders across every project

For full documentation, see [README.md](README.md) and [.github/copilot-instructions.md](.github/copilot-instructions.md).
