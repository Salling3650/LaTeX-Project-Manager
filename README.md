# LaTeX Project Manager

A terminal-based menu script for creating and managing LaTeX projects from templates.

## Features

- Create a blank LaTeX project
- Create a project from a template folder
- Open an existing project in Neovim
- Auto-compiles to PDF after editing

## Templates

Place your own template folders inside the `templates/` directory.  
Each subfolder will appear as an option in the **Template selector** menu.

```
templates/
    My Template/
        main.tex
        ...
```

## Usage

```bash
chmod +x menu.sh
./menu.sh
```

See [INSTALL.md](INSTALL.md) for setup and requirements.
