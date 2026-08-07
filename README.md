# LaTeX Manager

A terminal UI for creating and managing LaTeX projects, built with Rust + [ratatui](https://github.com/ratatui-org/ratatui).

## Features

- **Blank project** — create a new project from `templates/main.tex`, open in Neovim, auto-compile
- **Template selector** — pick a full template folder, name the project, open in Neovim, auto-compile
- **Open project** — recursively browse existing projects, open in Neovim, auto-compile
- **Multiple project roots** — configure extra folders (e.g. university vs. personal) via `project_root` in `tui.conf`; you'll be asked which to use when creating or opening
- **Type to filter** — inside any browser, just start typing to narrow the list down; arrow keys move the selection, Backspace on an empty filter goes up a folder
- **Rename / delete** — while browsing projects, `Ctrl+R` renames and `Ctrl+D` deletes the highlighted folder or project (delete asks for confirmation first)
- **Recent projects** — a new menu item showing your last few opened/created projects, labelled `RootLabel:relative/path` (e.g. `Uni:2026-Fall/CS301/hw1`)
- **Template variables** — `{{DATE}}`, `{{CLASS}}`, and `{{PROJECT}}` in any `.tex`/`.bib`/`.cls`/`.sty` file get filled in automatically when a project is created. `{{CLASS}}` is the folder directly above the project (e.g. `SurveyDesign` in `Efterår-2026/SurveyDesign/hw1`); `{{PROJECT}}` is the project's own folder name. A flat name with no `/` just leaves `{{CLASS}}` empty.
- **Compile error highlighting** — the compile popup colours `! ` fatal errors red, warnings yellow, and jumps straight to the first error when compilation finishes; the popup title shows an error/warning count
- **Clean build folders** — a new menu item that finds every `.build/` folder across all configured roots, shows how much space they're using, and deletes them all on confirmation
- **Nested project names** — organize projects into folders by typing a name with `/`, e.g. `2026-Fall/CS301/hw1`, or by browsing into subfolders you created by hand
- Streamed compile output in a popup window
- Auto-opens the PDF in your configured viewer after a successful compile
- Adaptive ASCII title banner (two-line large font, falls back to smaller sizes as the window shrinks)

## Usage

```bash
lx          # if the lx symlink is set up (see QUICKSTART.md)
# or
cd /path/to/Latex && ./tui/tui
```

### CLI shortcuts

For quick actions without navigating the menu:

```bash
lx 2026-Fall/CS301/hw4                      # opens it if it exists, creates it if not
lx 2026-Fall/CS301/hw4 -t lab-report        # same, but from a template if it needs creating
lx new 2026-Fall/CS301/hw4                  # always create — errors instead of opening if it exists
lx new hw5 --root Personal                  # pick a root when more than one is configured
lx open cs301                               # open by name; picker shown if more than one match
lx -r                                       # or: lx recent — reopen your last project
lx -h                                       # or: lx --help
```

## Configuration

Edit `tui/tui.conf` to customise colours and the PDF viewer:

```ini
# PDF viewer — command to open the compiled PDF (path is appended as the last argument)
# Leave unset to auto-detect a per-platform default (open / xdg-open / start)
# pdf_viewer = zathura

accent_color = cyan
footer_color = dark_gray
```

## Layout

```
Latex/
    tui/            ← Rust source, config, font files
        tui         ← binary, built locally by setup.sh / build.sh (not committed to git)
        tui.conf    ← runtime configuration
        fonts/      ← bundled FIGlet fonts used at build time
    templates/      ← template folders (each subfolder = one option)
        main.tex    ← used for "Blank project"
    projects/       ← default project root, created automatically on first project
```

See [QUICKSTART.md](QUICKSTART.md) for build instructions and dependencies.
