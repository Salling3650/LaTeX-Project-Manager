# LaTeX Manager

A terminal UI for creating and managing LaTeX projects, built with Rust + [ratatui](https://github.com/ratatui-org/ratatui).

## Features

- **Blank project** — create a new project from `templates/main.tex`, open in Neovim, auto-compile
- **Template selector** — pick a full template folder, name the project, open in Neovim, auto-compile
- **Open project** — browse existing projects, open in Neovim, auto-compile
- **Open project folder** — reveal the workspace in Finder
- Streamed compile output in a popup window
- Auto-opens the PDF in `tdf` after a successful compile

## Usage

```bash
lx          # if the lx symlink is set up (see INSTALL.md)
# or
cd /path/to/Latex && ./tui/target/release/tui
```

## Layout

```
Latex/
    tui/            ← Rust source + binary
    templates/      ← template folders (each subfolder = one option)
        main.tex    ← used for "Blank project"
        Stor opgave/
        Lille opgave/
    projects/       ← created automatically on first project
```

See [INSTALL.md](INSTALL.md) for build instructions and dependencies.
