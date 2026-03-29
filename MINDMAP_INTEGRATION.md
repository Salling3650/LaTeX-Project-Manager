# LaTeX Mindmap Integration

Your TUI now includes a **"Convert to mindmap"** menu option that lets you select any project and instantly generate an interactive HTML mind map.

## How It Works

1. Select **"Convert to mindmap"** from the TUI menu
2. Choose a project folder
3. The converter automatically:
   - Finds `main.tex` in that folder
   - Generates an interactive HTML mind map
   - Opens it in your browser
   - Saves output as `main_mindmap.html` in the project folder

## Setup

The integration uses a portable shell script (`latex-to-mindmap-portable.sh`) that:
- Finds the converter project automatically
- Installs dependencies on first run if needed (pylatexenc, markmap-cli)
- Works across different machines if you set the `LATEX_MINDMAP_PROJECT` environment variable

### Optional: Set Environment Variable (for other machines)

If you want to use this on another computer, define:

```bash
# In ~/.zshrc or ~/.bashrc
export LATEX_MINDMAP_PROJECT="/path/to/latex-to-mindmap"
```

This tells the script where to find the converter. If not set, it looks for the converter in:
1. `../latex-to-mindmap` (relative to TUI)
2. `/Users/REDACTED/Desktop/projects/Programming/1_Work_in_progress/LaTeX_mindmap/latex to mindmap` (default)

## What Gets Generated

- **HTML file**: `projectname_mindmap.html` - Interactive mind map with expandable sections
- **Markdown file**: `projectname_mindmap.md` - Flat hierarchical structure

Both are saved in your project folder alongside your `.tex` files.

## Dependencies

The script automatically installs (on first use):
- **pylatexenc** - For accurate LaTeX parsing
- **markmap-cli** - For HTML rendering (requires Node.js/npm)

If installation fails, you can manually install:
```bash
pip install pylatexenc
npm install -g markmap-cli
```
