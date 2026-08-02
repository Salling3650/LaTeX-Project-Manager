use ratatui::style::Color;
use std::collections::HashMap;
use std::env;
use std::fs;
use std::io;
use std::path::PathBuf;

// ─────────────────────────────────────────────────────────────────────────────
// Parsed configuration loaded from tui.conf at startup
// ─────────────────────────────────────────────────────────────────────────────

/// A single project workspace root: a directory that new/existing LaTeX
/// projects live under, plus a display label shown in the browser.
#[derive(Clone)]
pub struct ProjectRoot {
    pub label: String,
    pub path:  PathBuf,
}

pub struct Config {
    pub accent_color:   Color,
    pub footer_color:   Color,
    pub workspace_root: PathBuf,
    pub project_roots:  Vec<ProjectRoot>,
    pub pdf_viewer:     String,
    pub editor:         String,
    pub latex_compiler: String,
    pub auto_compile:   bool,
}

impl Default for Config {
    fn default() -> Self {
        let workspace_root = find_workspace_root();
        let project_roots = build_project_roots(&workspace_root, Vec::new());
        Config {
            accent_color:   Color::Cyan,
            footer_color:   Color::DarkGray,
            workspace_root,
            project_roots,
            pdf_viewer:     default_pdf_viewer(),
            editor:         "nvim".to_string(),
            latex_compiler: "pdflatex".to_string(),
            auto_compile:   true,
        }
    }
}

/// Best-effort platform default for opening a PDF. Only used when
/// `pdf_viewer` isn't set in tui.conf — an explicit config value always wins.
fn default_pdf_viewer() -> String {
    if cfg!(target_os = "macos") {
        "open".to_string()
    } else if cfg!(target_os = "windows") {
        "start".to_string()
    } else {
        // Linux and other Unix-likes
        "xdg-open".to_string()
    }
}

/// Build the final list of project roots: the default `<workspace_root>/projects`
/// (labelled after the workspace folder's name) plus any extra roots the user
/// configured via `project_root = ...` lines. Missing directories are created
/// so the browser never has to special-case a not-yet-existing root.
fn build_project_roots(workspace_root: &std::path::Path, mut extra: Vec<ProjectRoot>) -> Vec<ProjectRoot> {
    let default_label = workspace_root
        .file_name()
        .map(|n| n.to_string_lossy().into_owned())
        .unwrap_or_else(|| "Projects".to_string());
    let mut roots = vec![ProjectRoot {
        label: default_label,
        path:  workspace_root.join("projects"),
    }];
    roots.append(&mut extra);
    for r in &roots {
        let _ = fs::create_dir_all(&r.path);
    }
    roots
}

/// Parse a `project_root` config value. Accepts either `Label:/path/to/dir`
/// or a bare `/path/to/dir` (in which case the folder name becomes the label).
fn parse_project_root(v: &str) -> ProjectRoot {
    // Guard against splitting on a Windows-style drive letter colon (e.g. "C:\...").
    if let Some((label, path)) = v.split_once(':') {
        if path.starts_with('/') || path.starts_with('~') || path.starts_with('.') {
            return ProjectRoot { label: label.trim().to_string(), path: expand_tilde(path.trim()) };
        }
    }
    let p = expand_tilde(v.trim());
    let label = p.file_name().map(|n| n.to_string_lossy().into_owned()).unwrap_or_else(|| v.to_string());
    ProjectRoot { label, path: p }
}

/// Walk up from CWD and binary location to find the workspace root
/// (the directory that contains a `templates/` subdirectory).
pub fn find_workspace_root() -> PathBuf {
    // 1. CWD has templates/ → use CWD
    if let Ok(cwd) = env::current_dir() {
        if cwd.join("templates").is_dir() {
            return cwd;
        }
    }
    // 2. Walk up from binary path — canonicalize first to resolve symlinks (e.g. /usr/local/bin/lx)
    if let Ok(exe) = env::current_exe() {
        let exe = fs::canonicalize(&exe).unwrap_or(exe);
        let mut dir = exe.parent().map(|p| p.to_path_buf()).unwrap_or_else(|| PathBuf::from("."));
        for _ in 0..6 {
            if dir.join("templates").is_dir() {
                return dir;
            }
            match dir.parent() {
                Some(p) => dir = p.to_path_buf(),
                None => break,
            }
        }
    }
    env::current_dir().unwrap_or_else(|_| PathBuf::from("."))
}

fn find_workspace_root_from_exe() -> PathBuf {
    if let Ok(exe) = env::current_exe() {
        let exe = fs::canonicalize(&exe).unwrap_or(exe);
        let mut dir = exe.parent().map(|p| p.to_path_buf()).unwrap_or_else(|| PathBuf::from("."));
        for _ in 0..6 {
            if dir.join("templates").is_dir() {
                return dir;
            }
            match dir.parent() {
                Some(p) => dir = p.to_path_buf(),
                None => break,
            }
        }
    }

    find_workspace_root()
}

/// Expand a leading `~` or `~/...` to the user's home directory.
/// `PathBuf::from` treats `~` as a literal character, so without this,
/// any `workspace_root` value starting with `~` silently fails the
/// `is_dir()` check below and gets ignored.
fn expand_tilde(path: &str) -> PathBuf {
    if let Some(rest) = path.strip_prefix('~') {
        if rest.is_empty() || rest.starts_with('/') {
            if let Ok(home) = env::var("HOME") {
                return PathBuf::from(home).join(rest.trim_start_matches('/'));
            }
        }
    }
    PathBuf::from(path)
}

fn name_to_color(s: &str) -> Option<Color> {
    match s.to_lowercase().as_str() {
        "black"          => Some(Color::Black),
        "red"            => Some(Color::Red),
        "green"          => Some(Color::Green),
        "yellow"         => Some(Color::Yellow),
        "blue"           => Some(Color::Blue),
        "magenta"        => Some(Color::Magenta),
        "cyan"           => Some(Color::Cyan),
        "white"          => Some(Color::White),
        "dark_gray"      => Some(Color::DarkGray),
        "gray"           => Some(Color::Gray),
        "light_red"      => Some(Color::LightRed),
        "light_green"    => Some(Color::LightGreen),
        "light_yellow"   => Some(Color::LightYellow),
        "light_blue"     => Some(Color::LightBlue),
        "light_magenta"  => Some(Color::LightMagenta),
        "light_cyan"     => Some(Color::LightCyan),
        _                => None,
    }
}

pub fn config_path() -> PathBuf {
    let root = find_workspace_root_from_exe();
    root.join("tui").join("tui.conf")
}

pub fn load() -> Config {
    let mut cfg = Config::default();
    let path = config_path();
    let text = match fs::read_to_string(&path) {
        Ok(t) => t,
        Err(_) => return cfg, // config is optional
    };

    // `project_root` may appear multiple times (one extra workspace per line),
    // so it's collected separately instead of going through the single-value
    // HashMap below, which would silently keep only the last occurrence.
    let mut extra_roots: Vec<ProjectRoot> = Vec::new();

    let pairs: HashMap<String, String> = text
        .lines()
        .filter(|l| !l.trim_start().starts_with('#') && l.contains('='))
        .filter_map(|l| {
            let mut parts = l.splitn(2, '=');
            let k = parts.next()?.trim().to_lowercase();
            // Do NOT lowercase the value — paths are case-sensitive
            let v = parts.next()?.trim().trim_matches('"').to_string();
            if k == "project_root" {
                extra_roots.push(parse_project_root(&v));
                return None;
            }
            Some((k, v))
        })
        .collect();

    macro_rules! pick_color {
        ($field:ident, $key:literal) => {
            if let Some(v) = pairs.get($key) {
                if let Some(c) = name_to_color(&v.to_lowercase()) { cfg.$field = c; }
            }
        };
    }

    pick_color!(accent_color, "accent_color");
    pick_color!(footer_color,   "footer_color");

    if let Some(v) = pairs.get("pdf_viewer") {
        cfg.pdf_viewer = v.clone();
    }

    if let Some(v) = pairs.get("editor") {
        cfg.editor = v.clone();
    }

    if let Some(v) = pairs.get("latex_compiler") {
        cfg.latex_compiler = v.clone();
    }

    if let Some(v) = pairs.get("auto_compile") {
        cfg.auto_compile = v.eq_ignore_ascii_case("true");
    }

    if let Some(v) = pairs.get("workspace_root") {
        let p = expand_tilde(v);
        if p.is_dir() {
            cfg.workspace_root = p;
        }
    }

    cfg.project_roots = build_project_roots(&cfg.workspace_root, extra_roots);

    cfg
}

fn upsert_key(text: &str, key: &str, value: &str) -> String {
    let mut found = false;
    let mut out: Vec<String> = Vec::new();

    for line in text.lines() {
        let trimmed = line.trim_start();
        if !trimmed.starts_with('#') {
            if let Some((k, _)) = trimmed.split_once('=') {
                if k.trim().eq_ignore_ascii_case(key) {
                    out.push(format!("{} = {}", key, value));
                    found = true;
                    continue;
                }
            }
        }
        out.push(line.to_string());
    }

    if !found {
        if !out.is_empty() {
            out.push(String::new());
        }
        out.push(format!("{} = {}", key, value));
    }

    let mut result = out.join("\n");
    if text.ends_with('\n') {
        result.push('\n');
    }
    result
}

pub fn save_editor(editor: &str) -> io::Result<()> {
    let path = config_path();
    let text = fs::read_to_string(&path).unwrap_or_default();
    let updated = upsert_key(&text, "editor", editor);
    fs::write(path, updated)
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent projects — a small MRU list stored next to tui.conf.
// Each line is "label<TAB>absolute path". Entries whose path no longer
// exists are silently dropped on load, so deleted/moved projects never
// need explicit cleanup.
// ─────────────────────────────────────────────────────────────────────────────

fn recent_path() -> PathBuf {
    match config_path().parent() {
        Some(p) => p.join(".recent_projects"),
        None => PathBuf::from(".recent_projects"),
    }
}

pub fn load_recent() -> Vec<(String, PathBuf)> {
    let text = match fs::read_to_string(recent_path()) {
        Ok(t) => t,
        Err(_) => return Vec::new(),
    };
    text.lines()
        .filter_map(|l| {
            let mut parts = l.splitn(2, '\t');
            let label = parts.next()?.to_string();
            let p = PathBuf::from(parts.next()?);
            if p.is_dir() { Some((label, p)) } else { None }
        })
        .collect()
}

/// Record (or bump to the front of) the recent-projects list.
pub fn record_recent(label: &str, path: &std::path::Path) {
    const MAX_RECENT: usize = 15;
    let mut list = load_recent();
    list.retain(|(_, p)| p != path);
    list.insert(0, (label.to_string(), path.to_path_buf()));
    list.truncate(MAX_RECENT);
    let text = list
        .iter()
        .map(|(l, p)| format!("{}\t{}", l, p.display()))
        .collect::<Vec<_>>()
        .join("\n");
    let _ = fs::write(recent_path(), text);
}
