# tui

The Rust terminal interface for LaTeX Manager, built with [Ratatui](https://github.com/ratatui-org/ratatui).

---

## Features

- ANSI Shadow ASCII art header (auto-scales to terminal height)
- Centered, keyboard-navigated menu
- Recursive, multi-root project browser with type-to-filter, rename (`Ctrl+R`), and delete (`Ctrl+D`, with confirmation)
- Recent-projects list (MRU, labelled `RootLabel:relative/path`)
- Popup overlays for command output, the project/template browser, and text input
- Colour theming via `tui.conf`
- All menu items live in one file — easy to customise

---

## Requirements

- Rust + Cargo — https://rustup.rs
- Python 3 + pyfiglet (for the ASCII art title at build time)

```bash
pip3 install pyfiglet
# or if your system pip is externally managed:
pipx install pyfiglet
```

---

## Build & Run

```bash
cargo run          # debug build
cargo run --release  # optimised
```

The compiled binary is not committed to git — build it locally with the commands above, or via `../setup.sh` / `../build.sh`.

---

## Customisation

### Change the title

Open `build.rs` and edit the constant at the top:

```rust
const TITLE: &str = "My Launcher";
```

Run `cargo build` — the figlet art regenerates automatically in both full and compact sizes.

---

### Add or edit menu items

All menu items live in `src/menu.rs`.
Each entry is a `MenuItem` with a `label` and an `action` closure that receives the loaded `Config`:

```rust
MenuItem {
    label: "My Script",
    action: |cfg| Action::LaunchOutput {
        title:   "My Script".into(),
        program: "python3".into(),
        args:    vec!["my_script.py".into()],
        dir:     Some(cfg.workspace_root.join("scripts")),
    },
},
```

Available action types (documented at the top of `src/menu.rs`):

| Action | What it does |
|--------|-------------|
| `CreateBlankProject { templates_dir, projects_roots }` | Create a project from `templates/main.tex` |
| `CreateFromTemplate { templates_dir, projects_roots }` | Browse and copy a full template folder |
| `OpenLatexProject { projects_roots }` | Recursively browse and open an existing project |
| `OpenRecent` | Show the MRU recent-projects list |
| `ConvertToMindmap { projects_roots, tui_dir }` | Convert a project to an interactive HTML mindmap |
| `LaunchOutput { title, program, args, dir }` | Runs a command and streams output into a popup |
| `RunInteractive { program, args, dir }` | Hands the full terminal to the program (nvim, REPLs, etc.) |
| `SetEditor` | Prompt for and save the editor (`nvim`/`vscode`) |
| `EditConfig` | Open `tui.conf` in the configured editor |
| `Quit` | Exits the TUI |

---

### Change colours

Edit `tui.conf` in this directory — changes take effect on next launch:

```ini
accent_color = cyan       # title art, menu highlight, ">" symbol
footer_color = dark_gray
```

Available colour names: `black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`,
`dark_gray`, `gray`, `light_red`, `light_green`, `light_yellow`, `light_blue`, `light_magenta`, `light_cyan`

---

## Key bindings

| Key | Action |
|-----|--------|
| `↑` / `↓` | Navigate menu / browser |
| `Enter` | Select item |
| (type letters) | Filter the current browser listing |
| `Ctrl+R` | Rename the highlighted project/folder (project browser only) |
| `Ctrl+D` | Delete the highlighted project/folder, with confirmation |
| `Esc` | Close popup / clear filter |
| `q` | Quit (main menu only) |

---

## CLI shortcuts

```bash
lx new 2026-Fall/CS301/hw4                  # blank project, opens + compiles
lx new 2026-Fall/CS301/hw4 -t lab-report    # from a template
lx new hw5 --root Personal                  # pick a root when more than one is configured
lx open cs301                               # open by name; picker shown if more than one match
lx -r                                       # or: lx recent — reopen your last project
lx -h                                       # or: lx --help
```

These resolve entirely before the TUI opens — an unknown project, missing template, or ambiguous root prints an error and exits instead of launching the interface.
