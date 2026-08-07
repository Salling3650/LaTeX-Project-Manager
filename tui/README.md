# tui

The Rust terminal interface for LaTeX Manager, built with [Ratatui](https://github.com/ratatui-org/ratatui).

---

## Features

- ANSI Shadow ASCII art header (auto-scales to terminal height)
- Centered, keyboard-navigated menu
- Recursive, multi-root project browser with type-to-filter, rename (`Ctrl+R`), and delete (`Ctrl+D`, with confirmation)
- Recent-projects list (MRU, labelled `RootLabel:relative/path`)
- Template variables (`{{DATE}}`, `{{CLASS}}`, `{{PROJECT}}`) auto-filled on project creation
- Compile popup highlights errors/warnings and jumps to the first error
- "Clean build folders" — finds and deletes every `.build/` folder across all roots, with a size estimate and confirmation first
- Popup overlays for command output, the project/template browser, and text input
- Colour theming via `tui.conf`
- All menu items live in one file — easy to customise

---

## Requirements

- Rust + Cargo — https://rustup.rs

That's it to build the TUI itself. The ASCII-art title is generated at compile time by the `figlet-rs` crate (a normal `[build-dependencies]` entry in `Cargo.toml`), so `cargo build` handles it automatically — no Python, no `pip install`, no system `figlet` binary needed.

(Separately, LaTeX itself and Neovim are needed to actually *use* the tool — see `../setup.sh` or `../QUICKSTART.md`, which install those for you.)

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

### Template variables

Any `.tex`, `.bib`, `.cls`, or `.sty` file copied into a new project has these tokens replaced automatically:

| Variable | Value |
|---|---|
| `{{DATE}}` | Today's date, `YYYY-MM-DD` |
| `{{CLASS}}` | The folder directly above the project (e.g. `SurveyDesign` in `Efterår-2026/SurveyDesign/hw1`); empty for a flat name with no `/` |
| `{{PROJECT}}` | The project's own folder name (e.g. `hw1`) |

This applies to "Blank project," "Template selector," and `lx new` alike — the values are derived from whatever name/path you give the project, not from any folder-naming convention it has to guess at.

**Caveat:** substitution is a plain text find-and-replace across the whole file, including inside LaTeX comments. If you write `{{CLASS}}` in a `%` comment to document your own template, it'll get replaced too. Keep any notes-to-self about a template's variables in a separate file (or this README) rather than inline in the `.tex` itself.

---

### Clean build folders

Recursively finds every directory literally named `.build` across all configured project roots, shows the total count and disk usage, and deletes them on confirmation. Exact-name match only (never a pattern), and nothing is deleted without an explicit "y" — one failed deletion (e.g. a permissions issue) doesn't stop the rest or crash the tool; the summary tells you if anything was skipped.

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
lx 2026-Fall/CS301/hw4                      # opens it if it exists, creates it if not
lx 2026-Fall/CS301/hw4 -t lab-report        # same, but from a template if it needs creating
lx new 2026-Fall/CS301/hw4                  # always create — errors instead of opening if it exists
lx new hw5 --root Personal                  # pick a root when more than one is configured
lx open cs301                               # open by name; picker shown if more than one match
lx -r                                       # or: lx recent — reopen your last project
lx -h                                       # or: lx --help
```

These resolve entirely before the TUI opens — an unknown project, missing template, or ambiguous root prints an error and exits instead of launching the interface. The bare `lx <name>` form checks for an exact existing match in each configured root first; if it's in more than one root at once, it'll ask you to disambiguate with `lx open` or `--root` rather than guessing.
