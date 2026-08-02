# Welcome to LaTeX Manager

This repository contains a **terminal UI for creating and managing LaTeX projects**.

## Get Started in 60 Seconds

```bash
./setup.sh
```

That's it! The script handles:
- Installing all dependencies
- Building the Rust TUI
- Setting up the `lx` command
- Configuring your PDF viewer

**→ See [QUICKSTART.md](../QUICKSTART.md) for detailed setup instructions**

## What You Can Do

- **Create projects** — Blank or from templates
- **Edit & compile** — Opens Neovim, auto-compiles with latexmk
- **Manage workspace** — Browse and organize projects
- **Convert to mindmap** — Turn LaTeX files into interactive HTML
- **Stream compilation** — Watch compile output in real time

## Requirements

- macOS or Linux
- 2GB disk space (mostly for Rust/LaTeX dependencies)
- ~10-15 minutes for first-time setup

## Architecture

This is a **Rust project** with:
- **TUI** — Terminal UI built with [Ratatui](https://github.com/ratatui-org/ratatui)
- **CLI tools** — Neovim integration, latexmk, template management
- **Configuration** — Color themes, PDF viewer, workspace paths

**→ For technical details, see [.github/copilot-instructions.md](copilot-instructions.md)**

## Key Bindings

| Key | Action |
|---|---|
| `↑`/`↓` | Navigate menu / browser |
| `Enter` | Select item |
| (type letters) | Filter the current browser listing |
| `Ctrl+R` / `Ctrl+D` | Rename / delete a project (in the browser) |
| `q` | Quit |

## Documentation

- **[QUICKSTART.md](../QUICKSTART.md)** — Setup and basic usage
- **[README.md](../README.md)** — Project overview and features
- **[.github/copilot-instructions.md](copilot-instructions.md)** — For developers/AI

## Troubleshooting

**Setup issues?** Check [QUICKSTART.md#troubleshooting](../QUICKSTART.md#troubleshooting)

**Build fails?** Make sure you have write permissions:
```bash
chmod -R u+w /path/to/Latex
```

## Next Steps

1. Run `./setup.sh`
2. Launch the TUI: `lx`
3. Create your first project
