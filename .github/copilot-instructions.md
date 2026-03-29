# Copilot Instructions for LaTeX Manager

## Project Overview

This is a **terminal UI launcher for managing LaTeX projects**, built with Rust + [Ratatui](https://github.com/ratatui-org/ratatui). The project has two main components:

1. **TUI** (`tui/`) — A Rust-based terminal interface for creating, opening, and compiling LaTeX projects
2. **LaTeX projects** (`projects/`) — User-created LaTeX documents managed by the TUI
3. **Templates** (`templates/`) — Template LaTeX projects for quick setup

## Architecture

### Rust TUI (`tui/` directory)

The terminal interface is organized around four core modules:

- **`src/main.rs`** — Event loop, terminal rendering, popup management (output streaming, file browser, text input)
- **`src/menu.rs`** — Menu item definitions and action types; edit this file to add/remove menu items
- **`src/config.rs`** — Configuration parser for `tui.conf` (colors, PDF viewer, workspace root)
- **`build.rs`** — Build-time script that generates ASCII title art from a hardcoded constant using figlet

Key concepts:

- **Actions** — Each menu item defines an `Action` enum variant (see `src/menu.rs` for available types)
- **Popups** — Streamed command output, directory browser, and text input all use the same popup overlay system
- **Workspace root detection** — The binary walks up from its location looking for a `templates/` directory; can be overridden in `tui.conf`

### Template System

Templates are folders inside `templates/` directory. When a user selects "Template selector", the TUI:
1. Shows a file browser of template folders
2. Prompts for a project name
3. Uses `rsync` to copy the template to `projects/<name>/`
4. Opens the project in Neovim and auto-compiles

### Project Layout

```
Latex/
├── tui/                    # Rust source, binary, config
│   ├── src/                # Rust modules (main.rs, menu.rs, config.rs)
│   ├── build.rs            # Build script for ASCII art generation
│   ├── Cargo.toml          # Rust dependencies
│   ├── Cargo.lock          # Lock file
│   ├── tui                 # Pre-built binary
│   ├── tui.conf            # Runtime configuration (colors, PDF viewer)
│   └── fonts/              # Figlet fonts used at build time
├── templates/              # Template LaTeX projects
│   └── main.tex            # Used for "Blank project" option
├── projects/               # User-created projects (auto-created on first use)
├── menu.sh                 # Legacy bash launcher (superseded by Rust TUI)
├── build.sh                # Build script for the TUI
├── latex-to-mindmap-portable.sh  # Mindmap converter integration
└── INSTALL.md, README.md   # Setup and usage documentation
```

## Initial Setup

### Quick Start (macOS & Linux)

```bash
./setup.sh
```

This automated script:
- Checks and installs all dependencies (Rust, Python, Neovim, LaTeX, rsync)
- Builds the TUI in release mode
- Creates an `lx` symlink for easy launching
- Configures the PDF viewer alias
- Detects the workspace root

**Supported:**
- **macOS:** Homebrew-based installation
- **Linux:** apt (Debian/Ubuntu) and pacman (Arch) supported

## Build and Test

### Build the TUI

```bash
cd tui
cargo build --release
```

The binary is generated at `tui/target/release/tui`.

To rebuild with code signing (macOS):
```bash
./build.sh
```

### Run the TUI

```bash
# From workspace root (templates/ must be discoverable)
cd .. && ./tui/tui

# Or if the `lx` symlink is set up
lx
```

### Debug/Development Build

```bash
cd tui
cargo run        # debug build with RUST_BACKTRACE
cargo run --release  # optimized
```

## Key Conventions

### Menu Items

All menu items are defined in `src/menu.rs` as a `MenuItem` struct:

```rust
MenuItem {
    label: "Item Name",
    action: |root| Action::SomeAction { /* args */ },
}
```

The closure receives the workspace root path and returns an `Action`. Available action types:

- `CreateBlankProject { templates_dir, projects_dir }` — Create from `templates/main.tex`
- `CreateFromTemplate { templates_dir, projects_dir }` — Browse and copy a template
- `OpenLatexProject { projects_dir }` — Browse and open a project
- `ConvertToMindmap { projects_dir, tui_dir }` — Convert project to interactive HTML mindmap
- `LaunchOutput { title, program, args, dir }` — Run command, stream output to popup
- `RunInteractive { program, args, dir }` — Full-terminal program (nvim, REPL, etc.)
- `RevealInFinder { path }` — Open folder in macOS Finder
- `Quit` — Exit the TUI

To add a menu item: add a new `MenuItem` to the `ITEMS` array in `src/menu.rs`, then rebuild.

### Configuration

Edit `tui.conf` at runtime to change colors and settings. No rebuild required:

```ini
accent_color = cyan
footer_color = dark_gray
pdf_viewer = open -a Preview   # macOS; can also be zathura, mupdf, etc.
workspace_root = /path/to/Latex  # optional; auto-detected from binary location
```

Available colors: `black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`, `dark_gray`, `gray`, `light_red`, `light_green`, `light_yellow`, `light_blue`, `light_magenta`, `light_cyan`

### ASCII Title Art

To change the title displayed at the top of the TUI:

1. Edit the `TITLE` constant in `tui/build.rs`
2. Rebuild: `cargo build` or `./build.sh`

The build script auto-generates ASCII art in two sizes (full and compact) that scale to terminal height.

### Dependencies

- **crossterm** — Terminal event handling (keyboard, mouse)
- **ratatui** — Terminal rendering and UI components
- **figlet-rs** — Used at build time to generate ASCII art

External tools:
- Rust + Cargo
- Python 3 + pyfiglet (build-time dependency for figlet)
- neovim — Opens `.tex` files for editing
- latexmk — Compiles LaTeX
- rsync — Copies template folders
- (Platform-specific: figlet, ReadLink compatibility)

### LaTeX Compilation

When a project is opened or created, the TUI spawns a subprocess running `latexmk` in a `.build/` subdirectory inside the project. Output is streamed to a popup window in real time.

### Mindmap Integration

The `latex-to-mindmap-portable.sh` script converts LaTeX projects to interactive mindmaps:
- Finds the converter project automatically or via `LATEX_MINDMAP_PROJECT` env var
- Installs dependencies (pylatexenc, markmap-cli) on first run
- Outputs `<projectname>_mindmap.html` and `<projectname>_mindmap.md`

## Codebase Notes

- **Platform support** — Primarily designed for macOS; Linux support exists (see INSTALL.md for platform-specific adjustments)
- **Terminal handling** — Uses Crossterm for cross-platform terminal control (raw mode, alternate screen, events)
- **Workspace root auto-detection** — Walks up from binary location looking for `templates/` directory; can be overridden in `tui.conf`
- **No external configuration** — All runtime state is in `tui.conf` and `~/.tui_note.txt` (sticky notes)

## Key Bindings

| Key | Action |
|-----|--------|
| `↑` / `↓` | Navigate menu |
| `Enter` | Select item |
| `Ctrl+N` | Toggle sticky note |
| `Esc` | Close popup / close note |
| `q` | Quit |

Inside the note panel, typing works normally. The note is auto-saved to `~/.tui_note.txt`.
