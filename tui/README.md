# tui

A terminal launcher built with [Ratatui](https://github.com/ratatui-org/ratatui) and Rust.  
Navigate your projects, run scripts, open apps, and jot notes — all from one keyboard-driven menu.

---

## Features

- ANSI Shadow ASCII art header (auto-scales to terminal height)
- Centered, keyboard-navigated menu
- Popup overlays for command output and file/folder browsing
- Sticky note panel (Ctrl+N) with autosave
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
Each entry is a `MenuItem` with a `label` and an `action` closure:

```rust
MenuItem {
    label: "My Script",
    action: || Action::LaunchOutput {
        title:   "My Script".into(),
        program: "python3".into(),
        args:    s(&["my_script.py"]),
        dir:     Some(home_dir().join("projects/my_project")),
    },
},
```

Available action types (documented at the top of `src/menu.rs`):

| Action | What it does |
|--------|-------------|
| `LaunchOutput { title, program, args, dir }` | Runs a command and streams output into a popup |
| `RunInteractive { program, args, dir }` | Hands the full terminal to the program (ncurses, REPLs, etc.) |
| `OpenVSCode { path }` | Opens a folder in VS Code |
| `OpenSSH { user, host }` | Opens SSH in a new Terminal window (macOS) |
| `OpenBrowser { dirs_only }` | File (`false`) or folder (`true`) picker |
| `Quit` | Exits the TUI |

---

### Change colours

Edit `tui.conf` in the project root — changes take effect on next launch:

```ini
accent_color      = cyan       # title art, menu highlight, ">" symbol
footer_color      = dark_gray
note_border_color = yellow
note_cursor_bg    = yellow
```

Available colour names: `black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`,
`dark_gray`, `gray`, `light_red`, `light_green`, `light_yellow`, `light_blue`, `light_magenta`, `light_cyan`

---

## Key bindings

| Key | Action |
|-----|--------|
| `↑` / `↓` | Navigate menu |
| `Enter` | Select item |
| `Ctrl+N` | Toggle sticky note |
| `Esc` | Close popup / close note |
| `q` | Quit |

Inside the note panel, typing works normally. `Ctrl+N` or `Esc` closes it.  
The note is saved automatically to `~/.tui_note.txt`.
