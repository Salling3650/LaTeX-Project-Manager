# LaTeX Manager

A terminal UI for creating and managing LaTeX projects, built with Rust + [ratatui](https://github.com/ratatui-org/ratatui).

## Features

- **Blank project** — create a new project from `templates/main.tex`, open in Neovim, auto-compile
- **Template selector** — pick a full template folder, name the project, open in Neovim, auto-compile
- **Open project** — browse existing projects, open in Neovim, auto-compile
- **Open project folder** — reveal the workspace in Finder
- Streamed compile output in a popup window
- Auto-opens the PDF in your configured viewer after a successful compile
- Adaptive ASCII title banner (two-line large font, falls back to smaller sizes as the window shrinks)

## Usage

```bash
lx          # if the lx symlink is set up (see INSTALL.md)
# or
cd /path/to/Latex && ./tui/tui
```

## Configuration

Edit `tui/tui.conf` to customise colours and the PDF viewer:

```ini
# PDF viewer — command to open the compiled PDF (path is appended as the last argument)
pdf_viewer = tdf          # default; can be: open -a Skim, zathura, mupdf, …

accent_color = cyan
footer_color = dark_gray
```

## Layout

```
Latex/
    tui/            ← Rust source, pre-built binary, font files
        tui         ← pre-built binary (run this directly, or via the lx symlink)
        tui.conf    ← runtime configuration
        fonts/      ← bundled FIGlet fonts used at build time
    templates/      ← template folders (each subfolder = one option)
        main.tex    ← used for "Blank project"
    projects/       ← created automatically on first project
```

See [INSTALL.md](INSTALL.md) for build instructions and dependencies.
