# Copilot Instructions for LaTeX Manager

## Project Overview

This is a **terminal UI launcher for managing LaTeX projects**, built with Rust + [Ratatui](https://github.com/ratatui-org/ratatui). The project has three main components:

1. **TUI** (`tui/`) — A Rust-based terminal interface for creating, opening, and compiling LaTeX projects
2. **LaTeX projects** — User-created LaTeX documents, organized under one or more configured project roots (see "Multiple project roots" below)
3. **Templates** (`templates/`) — Template LaTeX projects for quick setup

## Architecture

### Rust TUI (`tui/` directory)

The terminal interface is organized around three source files (kept as a single small crate rather than split into many modules):

- **`src/main.rs`** — Event loop, terminal rendering, popup management (output streaming, recursive/multi-root project browser, text input, yes/no confirm)
- **`src/menu.rs`** — Menu item definitions and action types; edit this file to add/remove menu items
- **`src/config.rs`** — Configuration parser for `tui.conf` (colors, PDF viewer, project roots, recent-projects persistence)
- **`build.rs`** — Build-time script that generates ASCII title art from a hardcoded constant using figlet

Key concepts:

- **Actions** — Each menu item defines an `Action` enum variant (see `src/menu.rs` for available types)
- **Popups** — Streamed command output, the project/template browser, text input, and yes/no confirmation all use the same popup overlay system
- **Recursive project browser** — Browsing a project root drills into subfolders (e.g. a semester → a class) until it finds one that directly contains files (e.g. `main.tex`), at which point that folder is treated as a selectable project. Type to filter the current folder's listing; `Ctrl+R` renames and `Ctrl+D` deletes (with confirmation) the highlighted entry.
- **Multiple project roots** — `<workspace_root>/projects/` is always included; additional roots can be added via repeated `project_root = Label:/path` lines in `tui.conf`. When more than one root is configured, creation/open/mindmap flows first ask which root to use.
- **Recent projects** — Opening or creating a project records it (as `RootLabel:relative/path`) to an MRU list stored next to `tui.conf`; stale entries (deleted/moved projects) are dropped automatically on read.
- **Workspace root detection** — The binary walks up from its location looking for a `templates/` directory; can be overridden in `tui.conf`

### Template System

Templates are folders inside `templates/` directory. When a user selects "Template selector", the TUI:
1. Shows a file browser of template folders
2. Prompts for a project name
3. Copies the template to `<projects_root>/<name>/`, filtering out build artifacts
4. Opens the project in Neovim and auto-compiles

### Project Layout

```
Latex/
├── tui/                    # Rust source, config (binary is built locally, not committed)
│   ├── src/                # Rust modules (main.rs, menu.rs, config.rs)
│   ├── build.rs             # Build script for ASCII art generation
│   ├── Cargo.toml           # Rust dependencies
│   ├── Cargo.lock           # Lock file
│   ├── tui.conf             # Runtime configuration (colors, PDF viewer, project roots)
│   └── fonts/                # Figlet fonts used at build time
├── templates/               # Template LaTeX projects
│   └── main.tex              # Used for "Blank project" option
├── projects/                # Default project root (auto-created on first use)
├── build.sh                 # Build script for the TUI
├── latex-to-mindmap-portable.sh  # Mindmap converter integration
└── README.md, QUICKSTART.md, MINDMAP_INTEGRATION.md  # Setup and usage documentation
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

The binary is generated at `tui/target/release/tui`. It is *not* committed to git — every machine builds its own, since a compiled binary is platform/architecture-specific.

To rebuild with code signing (macOS):
```bash
./build.sh
```

### Run the TUI

```bash
# From workspace root (templates/ must be discoverable)
cd .. && ./tui/target/release/tui

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
    action: |cfg| Action::SomeAction { /* args, drawn from cfg */ },
}
```

The closure receives the full `Config` (not just a root path) and returns an `Action`. Available action types:

- `CreateBlankProject { templates_dir, projects_roots }` — Create from `templates/main.tex`
- `CreateFromTemplate { templates_dir, projects_roots }` — Browse and copy a template
- `OpenLatexProject { projects_roots }` — Recursively browse and open a project
- `OpenRecent` — Show the MRU recent-projects list
- `ConvertToMindmap { projects_roots, tui_dir }` — Convert project to interactive HTML mindmap
- `LaunchOutput { title, program, args, dir }` — Run command, stream output to popup
- `RunInteractive { program, args, dir }` — Full-terminal program (nvim, REPL, etc.)
- `Quit` — Exit the TUI

To add a menu item: add a new `MenuItem` to the `ITEMS` array in `src/menu.rs`, then rebuild.

### Configuration

Edit `tui.conf` at runtime to change colors and settings. No rebuild required:

```ini
accent_color = cyan
footer_color = dark_gray
pdf_viewer = open -a Preview   # optional; auto-detected per-platform if unset
workspace_root = /path/to/Latex  # optional; auto-detected from binary location
project_root = Uni:~/School/Latex/projects  # optional, repeatable
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
- latexmk / pdflatex — Compiles LaTeX
- (Platform-specific: figlet, ReadLink compatibility)

### LaTeX Compilation

When a project is opened or created, the TUI spawns a subprocess running the configured LaTeX compiler in a `.build/` subdirectory inside the project. Output is streamed to a popup window in real time.

### Mindmap Integration

The `latex-to-mindmap-portable.sh` script converts LaTeX projects to interactive mindmaps:
- Finds the converter project automatically or via `LATEX_MINDMAP_PROJECT` env var
- Installs dependencies (pylatexenc, markmap-cli) on first run
- Outputs `<projectname>_mindmap.html` and `<projectname>_mindmap.md`

### CLI Shortcuts

`main()` parses `env::args()` before any terminal setup. `lx new <name> [-t template] [--root label]`, `lx open <query>`, and `lx recent`/`lx -r` all resolve entirely on the filesystem first via `resolve_cli()` — a bad root, missing template, name collision, or zero matches prints to stderr and exits (code 1) without ever entering raw mode / the alternate screen. Only a successful resolution proceeds into the terminal: either `CliStartState::OpenDirect` (open the editor + stream the compile popup) or `CliStartState::ShowPicker` (multiple `open` matches — reuses the recent-projects picker UI). Both pre-seed `App`'s `workflow`/`popup` before the event loop starts, reusing the exact same code a menu selection would use. `lx -h`/`--help` exits before even loading `tui.conf`.

## Codebase Notes

- **Platform support** — macOS and Linux (Debian/Ubuntu via apt, Arch via pacman); `setup.sh` handles both
- **Terminal handling** — Uses Crossterm for cross-platform terminal control (raw mode, alternate screen, events)
- **Workspace root auto-detection** — Walks up from binary location looking for `templates/` directory; can be overridden in `tui.conf`
- **Project roots** — One or more folders projects live under; configured via `project_root` lines in `tui.conf`, always including `<workspace_root>/projects/`
- **State on disk** — `tui.conf` (settings) and `.recent_projects` (MRU list, stored alongside `tui.conf`) are the only persistent state

## Key Bindings

| Key | Action |
|-----|--------|
| `↑` / `↓` | Navigate menu / browser |
| `Enter` | Select item |
| (type letters) | Filter the current browser listing |
| `Ctrl+R` | Rename highlighted project/folder (in the project browser) |
| `Ctrl+D` | Delete highlighted project/folder, with confirmation |
| `Esc` | Close popup / clear filter |
| `q` | Quit (main menu only) |
