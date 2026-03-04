#!/usr/bin/env bash

# ============================================
# MENU CONFIGURATION (Easy to Modify)
# ============================================
MENU_SELECTOR_SYMBOL=">"
MENU_SELECTED_COLOR=$'\e[1;34m'  # Bold Blue
MENU_NORMAL_COLOR=$'\e[0m'        # Reset
MENU_CURSOR_VISIBLE=false
MENU_CLEAR_AFTER_SELECT=true

# ============================================
# FILE SELECTOR CONFIGURATION
# ============================================
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
FILES_DIR="$SCRIPT_DIR/templates"
Project_DIR="$SCRIPT_DIR/projects"

# ============================================
# ADVANCED MENU SELECTOR FUNCTION
# ============================================
# Usage Examples:
#   advanced_menu_selector "Choose:" choice "Option 1" "Option 2" "Option 3"
#   advanced_menu_selector "Select:" result "Display A" "Display B" -- "value_a" "value_b"
#
# Arguments:
#   $1: Prompt message
#   $2: Variable name to store result
#   $@: Options (display text, optionally followed by -- and return values)
#
# Returns:
#   0 on success
#   1 on error
#   130 on cancellation (Ctrl+C, q, or Q)
# ============================================
function advanced_menu_selector() {
    local -r prompt="$1" outvar="$2"
    shift 2
    local -a display_options=() return_values=()
    local parsing_display=true

    # Parse display options and return values
    while [[ $# -gt 0 ]]; do
        if [[ "$1" == "--" ]]; then
            parsing_display=false
            shift
            continue
        fi
        if $parsing_display; then
            display_options+=("$1")
        else
            return_values+=("$1")
        fi
        shift
    done

    # If no return values specified, use display options as return values
    if (( ${#return_values[@]} == 0 )); then
        return_values=("${display_options[@]}")
    fi

    # Validation
    local count=${#display_options[@]}
    if (( count == 0 )); then
        echo "Error: No options provided" >&2
        return 1
    fi
    if (( ${#display_options[@]} != ${#return_values[@]} )); then
        echo "Error: Mismatched display and return value arrays" >&2
        return 1
    fi

    # Setup terminal
    local cur=0
    $MENU_CURSOR_VISIBLE || tput civis 2>/dev/null
    trap 'tput cnorm 2>/dev/null; stty echo 2>/dev/null' EXIT INT TERM
    stty -echo 2>/dev/null

    printf "%s\n" "$prompt"

    # Main selection loop
    while true; do
        local index=0
        for o in "${display_options[@]}"; do
            if [[ $index == $cur ]]; then
                printf " %s%s %s %s\n" "${MENU_SELECTOR_SYMBOL}" "${MENU_SELECTED_COLOR}" "$o" "${MENU_NORMAL_COLOR}"
            else
                printf "   %s\n" "$o"
            fi
            (( ++index ))
        done

        printf "\e[97m↑↓\e[0m \e[2;37mnavigate\e[0m \e[97m• ⏎\e[0m \e[2;37mselect\e[0m\n"

        # Read user input
        IFS= read -rsn1 key
        case "$key" in
            $'\x1b')  # ESC sequence
                read -rsn2 rest
                case "$rest" in
                    '[A') (( cur = (cur - 1 + count) % count )) ;;  # Up arrow
                    '[B') (( cur = (cur + 1) % count )) ;;          # Down arrow
                esac
                ;;
            ''|$'\n'|$'\r')  # Enter
                break
                ;;
            $'\003'|q|Q)  # Ctrl+C or q or Q
                tput cnorm 2>/dev/null; stty echo 2>/dev/null; trap - EXIT INT TERM
                printf "\e[%dA" "$count"
                printf "\nSelection cancelled\n" >&2
                return 130
                ;;
        esac

        # Move cursor back up (menu items + help text line)
        printf "\e[%dA" "$((count + 1))"
    done

    # Cleanup terminal
    tput cnorm 2>/dev/null
    stty echo 2>/dev/null
    trap - EXIT INT TERM

    # Clear menu if configured (prompt + options + help text = count + 2 lines)
    if $MENU_CLEAR_AFTER_SELECT; then
        printf "\e[%dA" "$((count + 2))"
        for (( i=0; i<count+2; i++ )); do printf "\e[2K\n"; done
        printf "\e[%dA" "$((count + 2))"
    fi

    # Set result and display selection
    printf -v "$outvar" "${return_values[$cur]}"
    #echo "Selected: ${display_options[$cur]} (value: ${return_values[$cur]})"

    return 0
}

# ============================================
# UTILITY FUNCTIONS
# ============================================
function pause_for_key() {
    echo ""
    read -n 1 -s -r -p "Press any key to continue..."
}

function compile_and_open() {
    echo "Compiling..."
    mkdir -p .build
    # Create subdirs in .build/ for any \include or \input with subdirectory paths
    grep -hE '\\(include|input)\{[^}]*/[^}]*\}' main.tex 2>/dev/null \
        | sed -E 's/.*\{([^}]+)\}.*/\1/' \
        | while read -r f; do mkdir -p ".build/$(dirname "$f")"; done
    # Set TEXINPUTS so LaTeX finds .sty and resource files in subdirs (e.g. Config/)
    TEXINPUTS=".:./Config//:$TEXINPUTS" latexmk -pdf -quiet -f -outdir=.build main.tex &>/dev/null
    if [[ -f "$(pwd)/.build/main.pdf" ]]; then
        tdf "$(pwd)/.build/main.pdf"
        tdf "$(pwd)/.build/main.pdf"
    else
        echo ""
        echo "Compilation failed. Run latexmk manually to see errors:"
        echo "  latexmk -pdf -outdir=.build main.tex"
        pause_for_key
    fi
}

function show_header() {
    clear
    figlet "LaTeX  Project  Manager"
}

# ============================================
# FILE SELECTOR
# ============================================
function select_file_from_dir() {
    local -r prompt="$1" outvar="$2" dir="$3"

    if [[ -z "$dir" || ! -d "$dir" ]]; then
        echo "Error: Directory not found: $dir" >&2
        return 1
    fi

    local -a files=() basenames=()
    while IFS= read -r file; do
        files+=("$file")
        basenames+=("$(basename "$file")")
    done < <(find "$dir" -maxdepth 1 -type f -print | sort)

    if (( ${#files[@]} == 0 )); then
        echo "No files found in: $dir" >&2
        return 1
    fi

    advanced_menu_selector "$prompt" "$outvar" "${basenames[@]}" -- "${files[@]}"
}

# ============================================
# FOLDER SELECTOR
# ============================================
function select_folder_from_dir() {
    local -r prompt="$1" outvar="$2" dir="$3"

    if [[ -z "$dir" || ! -d "$dir" ]]; then
        echo "Error: Directory not found: $dir" >&2
        return 1
    fi

    local -a folders=() basenames=()
    while IFS= read -r folder; do
        folders+=("$folder")
        basenames+=("$(basename "$folder")")
    done < <(find "$dir" -maxdepth 1 -mindepth 1 -type d -print | sort)

    if (( ${#folders[@]} == 0 )); then
        echo "No folders found in: $dir" >&2
        return 1
    fi

    advanced_menu_selector "$prompt" "$outvar" "${basenames[@]}" -- "${folders[@]}"
}


# ============================================
# MAIN SCRIPT
# ============================================

show_header

while true; do
advanced_menu_selector "Choose an action:" choice "Blank project" "Template selector" "Open project" "Open project folder" "Exit"
# Check if user cancelled (pressed q, Q, or Ctrl+C)
if [[ $? -eq 130 ]]; then
    clear
    break
fi
if [[ "$choice" == "Blank project" ]]; then
    read -p "Enter project name: " projectname
    mkdir -p "$Project_DIR/$projectname"
    cp "$FILES_DIR/main.tex" "$Project_DIR/$projectname/main.tex"
    cd "$Project_DIR/$projectname" && nvim main.tex # Open project in Neovim
    compile_and_open

elif [[ "$choice" == "Template selector" ]]; then
    if select_folder_from_dir "Select a template:" selected_folder "$FILES_DIR"; then
        echo "Selected template: $selected_folder"
        read -p "Enter project name: " projectname
        mkdir -p "$Project_DIR/$projectname"
        rsync -a --exclude='.build' --exclude='*.aux' --exclude='*.log' --exclude='*.fdb_latexmk' --exclude='*.fls' --exclude='*.synctex.gz' --exclude='*.toc' --exclude='*.out' --exclude='missfont.log' --exclude='main.pdf' "$selected_folder"/ "$Project_DIR/$projectname/" # Copy template contents into project folder
        cd "$Project_DIR/$projectname" && nvim main.tex
        compile_and_open
    fi
    pause_for_key
    show_header

elif [[ "$choice" == "Open project" ]]; then
    if select_folder_from_dir "Select a project:" selected_project "$Project_DIR"; then
        cd "$selected_project" && nvim main.tex 
        compile_and_open
    fi
    show_header

elif [[ "$choice" == "Open project folder" ]]; then
    open "$SCRIPT_DIR"

elif [[ "$choice" == "Exit" ]]; then
  clear
  break
else
  echo "You chose: $choice"
fi
done