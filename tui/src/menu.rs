// ─────────────────────────────────────────────────────────────────────────────
//  MENU CONFIGURATION — LaTeX Project Manager
//  ─────────────────────────────────────────────────────────────────────────────
//  Edit the ITEMS list below to add, remove, or reorder menu entries.
//
//  Available actions:
//
//    Action::CreateBlankProject { templates_dir, projects_roots }
//        If more than one project root is configured, prompts to pick one
//        first. Then prompts for a project name (may include `/` to nest
//        it, e.g. "2026-Fall/CS301/hw1"), copies templates/main.tex into
//        <root>/<name>/main.tex, opens the editor, then compiles.
//
//    Action::CreateFromTemplate { templates_dir, projects_roots }
//        Same root-picking behaviour as above, then shows a template-folder
//        browser, prompts for a project name, copies the selected template
//        to <root>/<name>/, opens the editor, then compiles.
//
//    Action::OpenLatexProject { projects_roots }
//        Shows a recursive, multi-root project browser: pick a root (if
//        more than one is configured), then drill into subfolders — a
//        folder is treated as a project once it directly contains files
//        (e.g. main.tex), otherwise selecting it just descends further.
//        Type to filter the current folder's contents. Ctrl+R renames and
//        Ctrl+D deletes (with a yes/no confirmation) the highlighted
//        folder or project. Opens the chosen project in the editor, then
//        compiles, and records it in the recent-projects list.
//
//    Action::OpenRecent
//        Shows the MRU list of recently opened/created projects, labelled
//        "RootLabel:relative/path" (e.g. "Uni:2026-Fall/CS301/hw1").
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
//    Action::ConvertToMindmap { projects_roots, tui_dir }
//        Same recursive, multi-root browser as OpenLatexProject, then
//        converts the selected project to an interactive mind map HTML file.
//
// ─────────────────────────────────────────────────────────────────────────────

use crate::config::{Config, ProjectRoot};
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
    /// Prompt for a name, create blank project from templates/main.tex, open editor.
    CreateBlankProject { templates_dir: PathBuf, projects_roots: Vec<ProjectRoot> },
    /// Browse templates/, prompt for a name, copy, open editor.
    CreateFromTemplate { templates_dir: PathBuf, projects_roots: Vec<ProjectRoot> },
    /// Recursively browse one or more project roots, open the selected project.
    OpenLatexProject { projects_roots: Vec<ProjectRoot> },
    /// Show the MRU list of recently opened/created projects.
    OpenRecent,
    /// Recursively browse one or more project roots, convert selection to mindmap.
    ConvertToMindmap { projects_roots: Vec<ProjectRoot>, tui_dir: PathBuf },
    EditConfig,
}

// ── A single menu entry ───────────────────────────────────────────────────────

pub struct MenuItem {
    pub label: &'static str,
    pub action: fn(&Config) -> Action,
}

// ─────────────────────────────────────────────────────────────────────────────
//  ↓↓↓  ADD / EDIT YOUR MENU ITEMS HERE  ↓↓↓
// ─────────────────────────────────────────────────────────────────────────────

pub const ITEMS: &[MenuItem] = &[

    MenuItem {
        label: "Blank project",
        action: |cfg| {
            Action::CreateBlankProject {
                templates_dir:  cfg.workspace_root.join("templates"),
                projects_roots: cfg.project_roots.clone(),
            }
        },
    },

    MenuItem {
        label: "Template selector",
        action: |cfg| {
            Action::CreateFromTemplate {
                templates_dir:  cfg.workspace_root.join("templates"),
                projects_roots: cfg.project_roots.clone(),
            }
        },
    },

    MenuItem {
        label: "Open project",
        action: |cfg| {
            Action::OpenLatexProject {
                projects_roots: cfg.project_roots.clone(),
            }
        },
    },

    MenuItem {
        label: "Recent projects",
        action: |_| Action::OpenRecent,
    },

    MenuItem {
        label: "Convert to mindmap",
        action: |cfg| {
            Action::ConvertToMindmap {
                projects_roots: cfg.project_roots.clone(),
                tui_dir: cfg.workspace_root.clone(),
            }
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
