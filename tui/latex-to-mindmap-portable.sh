#!/bin/bash
# Portable LaTeX to Mindmap Converter
# Use this from any LaTeX project directory to convert to mindmap
# 
# Usage: 
#   Place this script in your project root or dotfiles
#   Run: ./latex-to-mindmap-portable.sh main.tex
#   Or:  /path/to/latex-to-mindmap-portable.sh /path/to/main.tex

set -e

# Get the LaTeX file path (relative or absolute)
LATEX_FILE="${1:-.}"

# If directory provided, look for main.tex inside it
if [ -d "$LATEX_FILE" ]; then
    if [ -f "$LATEX_FILE/main.tex" ]; then
        LATEX_FILE="$LATEX_FILE/main.tex"
    else
        echo "Error: No main.tex found in directory: $LATEX_FILE"
        exit 1
    fi
fi

# Resolve to absolute path
if [[ "$LATEX_FILE" != /* ]]; then
    LATEX_FILE="$(cd "$(dirname "$LATEX_FILE")" && pwd)/$(basename "$LATEX_FILE")"
fi

if [ ! -f "$LATEX_FILE" ]; then
    echo "Error: File not found: $LATEX_FILE"
    exit 1
fi

# Find the converter project
# Priority: LATEX_MINDMAP_PROJECT env var > ../latex-to-mindmap > default location
if [ -n "$LATEX_MINDMAP_PROJECT" ]; then
    CONVERTER_DIR="$LATEX_MINDMAP_PROJECT"
elif [ -d "../latex-to-mindmap" ]; then
    CONVERTER_DIR="$(cd ../latex-to-mindmap && pwd)"
elif [ -d "../latex to mindmap" ]; then
    CONVERTER_DIR="$(cd "../latex to mindmap" && pwd)"
else
    # Default fallback location
    CONVERTER_DIR="/Users/REDACTED/Desktop/projects/Programming/0_Done/LaTeX_mindmap/latex to mindmap"
fi

if [ ! -f "$CONVERTER_DIR/latex_to_mindmap.py" ]; then
    echo "Error: Could not find latex_to_mindmap.py in $CONVERTER_DIR"
    echo "Set LATEX_MINDMAP_PROJECT env var or place script near the converter"
    exit 1
fi

# Determine output location
PROJECT_DIR="$(dirname "$LATEX_FILE")"
FILENAME=$(basename "$LATEX_FILE" .tex)
OUTPUT_HTML="$PROJECT_DIR/${FILENAME}_mindmap.html"
OUTPUT_MD="$PROJECT_DIR/${FILENAME}_mindmap.md"

echo "Converting: $LATEX_FILE"
echo "Output: $OUTPUT_HTML"

# Check if pylatexenc is installed
if ! python3 -c "import pylatexenc" 2>/dev/null; then
    echo "⚠️  Installing pylatexenc..."
    pip install --break-system-packages pylatexenc >/dev/null 2>&1 || \
    pip3 install pylatexenc >/dev/null 2>&1 || {
        echo "Error: Could not install pylatexenc"
        echo "Run: pip install pylatexenc"
        exit 1
    }
fi

# Check if markmap-cli is installed
if ! command -v markmap &> /dev/null; then
    echo "⚠️  Installing markmap-cli..."
    npm install -g markmap-cli >/dev/null 2>&1 || {
        echo "Error: Could not install markmap-cli (requires npm)"
        echo "Install Node.js or run: npm install -g markmap-cli"
        exit 1
    }
fi

# Step 1: Convert LaTeX to Markdown
cd "$CONVERTER_DIR"
python3 latex_to_mindmap.py "$LATEX_FILE" --markmap-mode --output "$OUTPUT_MD" || exit 1

# Step 2: Convert Markdown to HTML
markmap "$OUTPUT_MD" --output "$OUTPUT_HTML" || exit 1

# Step 3: Open in browser
open "$OUTPUT_HTML" 2>/dev/null || xdg-open "$OUTPUT_HTML" 2>/dev/null || echo "✓ Created: $OUTPUT_HTML"

echo "✓ Mindmap ready: $OUTPUT_HTML"
