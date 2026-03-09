# LaTeX Manager – Setup Guide

> Primarily designed for **macOS**.

## Requirements

| Tool | Purpose | Install |
|------|---------|--------|
| `rust` + `cargo` | Build the TUI | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |
| `python3` + `pyfiglet` | ASCII title (build-time only) | `pip3 install pyfiglet` |
| `nvim` | Edit `.tex` files | `brew install neovim` |
| `latexmk` | Compile LaTeX | Included with MacTeX / BasicTeX |
| `tdf` | Open PDF in terminal | See note below |
| `rsync` | Copy templates | Pre-installed on macOS |

## Build

```bash
cd /path/to/Latex/tui
cargo build --release
```

The binary is at `tui/target/release/tui`.

## Quick launch with `lx`

Create a global symlink so you can type `lx` anywhere:

```bash
ln -sf "$(pwd)/tui/target/release/tui" /usr/local/bin/lx
```

Then run from the workspace root (so `templates/` is found automatically):

```bash
cd /path/to/Latex && lx
```

## LaTeX distribution

```bash
# Full MacTeX (~5 GB)
brew install --cask mactex

# Or BasicTeX (~100 MB) + latexmk
brew install --cask basictex
sudo tlmgr update --self && sudo tlmgr install latexmk
```

## `tdf` – PDF viewer

The TUI calls `tdf <path>` after a successful compile. Set it up as an alias in `~/.zshrc`:

```bash
# macOS Preview
echo 'alias tdf="open -a Preview"' >> ~/.zshrc

# Skim
echo 'alias tdf="open -a Skim"' >> ~/.zshrc

# zathura (Linux)
echo 'alias tdf="zathura"' >> ~/.zshrc

source ~/.zshrc
```

## Workspace auto-detection

The binary finds the workspace root by walking up from its location looking for a `templates/` directory. You can also override it in `tui/tui.conf`:

```
workspace_root = /path/to/Latex
```

## Customising the TUI

Edit `tui/tui.conf` to change colours:

```
accent_color = cyan
footer_color = dark_gray
```

Edit `tui/src/menu.rs` to add, remove, or reorder menu items, then rebuild:

```bash
cargo build --release
```

| `bash` | Run the script | Pre-installed on macOS |
| `figlet` | Header banner | `brew install figlet` |
| `nvim` | Edit `.tex` files | `brew install neovim` |
| `latexmk` | Compile LaTeX | Included with MacTeX |
| `tdf` | Open PDF | See note below |
| `rsync` | Copy templates | Pre-installed on macOS |

## Install Dependencies

### macOS

```bash
# Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Tools
brew install figlet neovim

# LaTeX (MacTeX – full distribution, ~5 GB)
brew install --cask mactex

# Or the smaller BasicTeX (~100 MB) + latexmk
brew install --cask basictex
sudo tlmgr update --self
sudo tlmgr install latexmk
```

### Linux (Debian/Ubuntu)

```bash
# Tools
sudo apt install figlet neovim rsync

# LaTeX
sudo apt install texlive-full latexmk
```

### Linux (Arch)

```bash
sudo pacman -S figlet neovim rsync texlive-most
```

## `tdf` – PDF Viewer

The script calls `tdf <path>` to open the compiled PDF.  
Set it up as an alias or script that points to your preferred PDF viewer:

**macOS:**
```bash
# alias in ~/.zshrc (e.g. using macOS Preview)
echo 'alias tdf="open -a Preview"' >> ~/.zshrc
source ~/.zshrc
```
Replace `Preview` with any viewer you prefer (e.g. `Skim`, `PDF Expert`).

**Linux:**
```bash
# Uses xdg-open (opens with your default PDF viewer)
echo 'alias tdf="xdg-open"' >> ~/.bashrc
source ~/.bashrc
```
Or point it to a specific viewer like `evince`, `okular`, or `zathura`:
```bash
echo 'alias tdf="zathura"' >> ~/.bashrc
```

## Project Structure

The script expects this layout (already in place if cloned correctly):

```
menu.sh
templates/        ← template folders go here
    main.tex      ← used for "Blank project"
projects/         ← created automatically on first use
```

## First-Time Setup

```bash
# 1. Clone or place the folder somewhere
cd /path/to/Latex

# 2. Make the script executable
chmod +x menu.sh

# 3. Run it
./menu.sh
```

## Notes

- **macOS `readlink -f`** – BSD `readlink` does not support `-f`. The script uses
  `readlink -f` inside `SCRIPT_DIR`. If you see errors, install GNU coreutils:
  ```bash
  brew install coreutils
  ```
  Then replace `readlink` with `greadlink` in `menu.sh`, or add this to `~/.zshrc`:
  ```bash
  export PATH="$(brew --prefix)/opt/coreutils/libexec/gnubin:$PATH"
  ```
  On **Linux**, `readlink -f` works natively — no fix needed.

- **`open "$SCRIPT_DIR"` (macOS only)** – The "Open project folder" option uses
  `open`, which launches Finder. On Linux, replace it with `xdg-open` in `menu.sh`:
  ```bash
  # In menu.sh, change:
  open "$SCRIPT_DIR"
  # To:
  xdg-open "$SCRIPT_DIR"
  ```

- The script compiles LaTeX into a `.build/` subdirectory inside each project to
  keep source files clean.
