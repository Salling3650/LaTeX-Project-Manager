// ─────────────────────────────────────────────────────────────────────────────
//  MENU CONFIGURATION — LaTeX Project Manager
//  ─────────────────────────────────────────────────────────────────────────────
//  Edit the ITEMS list below to add, remove, or reorder menu entries.
//
//  Available actions:
//
//    Action::CreateBlankProject { templates_dir, projects_dir }
//        Prompts for a project name, copies templates/main.tex to
//        projects/<name>/main.tex, opens nvim, then compiles.
//
//    Action::CreateFromTemplate { templates_dir, projects_dir }
//        Shows a template-folder browser, prompts for a project name,
//        rsyncs the selected template to projects/<name>/, opens nvim,
//        then compiles.
//
//    Action::OpenLatexProject { projects_dir }
//        Shows a project-folder browser, opens the selected project in
//        nvim, then compiles.
//
//    Action::RevealInFinder { path }
//        Opens a folder in macOS Finder.
//
//    Action::LaunchOutput { title, program, args, dir }
//        Runs a command and streams its output into a popup window.
//
//    Action::RunInteractive { program, args, dir }
//        Hands the full terminal to the program (nvim, etc.).
//
//    Action::Quit
//        Exits the TUI.
//
//    Action::ConvertToMindmap { tui_dir }
//        Lets the user select a LaTeX project, then converts it to an
//        interactive mind map HTML file using the portable converter.
//
// ─────────────────────────────────────────────────────────────────────────────

use std::path::PathBuf;

// ── The action each menu item triggers ───────────────────────────────────────

#[allow(dead_code)]
pub enum Action {
    Quit,
    SetEditor,
    /// Run a long command and stream its output into a popup window.
    LaunchOutput { title: String, program: String, args: Vec<String>, dir: Option<PathBuf> },
    /// Hand the terminal to an interactive program (e.g. nvim), return on exit.
    RunInteractive { program: String, args: Vec<String>, dir: Option<PathBuf> },
    /// Open a folder in macOS Finder.
    RevealInFinder { path: PathBuf },
    /// Prompt for a name, create blank project from templates/main.tex, open nvim.
    CreateBlankProject { templates_dir: PathBuf, projects_dir: PathBuf },
    /// Browse templates/, prompt for a name, rsync, open nvim.
    CreateFromTemplate { templates_dir: PathBuf, projects_dir: PathBuf },
    /// Browse projects/, open the selected project in nvim.
    OpenLatexProject { projects_dir: PathBuf },
    /// Browse projects/, select one, convert to mindmap HTML.
    ConvertToMindmap { projects_dir: PathBuf, tui_dir: PathBuf },
    EditConfig,
}

// ── A single menu entry ───────────────────────────────────────────────────────

pub struct MenuItem {
    pub label: &'static str,
    pub action: fn(&std::path::Path) -> Action,
}

// ─────────────────────────────────────────────────────────────────────────────
//  ↓↓↓  ADD / EDIT YOUR MENU ITEMS HERE  ↓↓↓
// ─────────────────────────────────────────────────────────────────────────────

pub const ITEMS: &[MenuItem] = &[

    MenuItem {
        label: "Blank project",
        action: |root| {
            Action::CreateBlankProject {
                templates_dir: root.join("templates"),
                projects_dir:  root.join("projects"),
            }
        },
    },

    MenuItem {
        label: "Template selector",
        action: |root| {
            Action::CreateFromTemplate {
                templates_dir: root.join("templates"),
                projects_dir:  root.join("projects"),
            }
        },
    },

    MenuItem {
        label: "Open project",
        action: |root| {
            Action::OpenLatexProject {
                projects_dir: root.join("projects"),
            }
        },
    },

    MenuItem {
        label: "Convert to mindmap",
        action: |root| {
            Action::ConvertToMindmap {
                projects_dir: root.join("projects"),
                tui_dir: root.to_path_buf(),
            }
        },
    },

    MenuItem {
        label: "Open project folder",
        action: |root| Action::RevealInFinder {
            path: root.to_path_buf(),
        },
    },

    MenuItem {
        label: "Set editor",
        action: |_| Action::SetEditor,
    },

    MenuItem {
        label: "Edit tui.conf",
        action: |_| Action::EditConfig,
    },

    MenuItem {
        label: "Exit",
        action: |_| Action::Quit,
    },
];

// ─────────────────────────────────────────────────────────────────────────────
//  ↑↑↑  END OF MENU ITEMS  ↑↑↑
// ─────────────────────────────────────────────────────────────────────────────
