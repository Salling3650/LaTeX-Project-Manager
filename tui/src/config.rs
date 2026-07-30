use ratatui::style::Color;
use std::collections::HashMap;
use std::env;
use std::fs;
use std::io;
use std::path::PathBuf;

// ─────────────────────────────────────────────────────────────────────────────
// Parsed configuration loaded from tui.conf at startup
// ─────────────────────────────────────────────────────────────────────────────

pub struct Config {
    pub accent_color:   Color,
    pub footer_color:   Color,
    pub workspace_root: PathBuf,
    pub pdf_viewer:     String,
    pub editor:         String,
    pub latex_compiler: String,
    pub auto_compile:   bool,
}

impl Default for Config {
    fn default() -> Self {
        Config {
            accent_color:   Color::Cyan,
            footer_color:   Color::DarkGray,
            workspace_root: find_workspace_root(),
            pdf_viewer:     "tdf".to_string(),
            editor:         "nvim".to_string(),
            latex_compiler: "pdflatex".to_string(),
            auto_compile:   true,
        }
    }
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

    let pairs: HashMap<String, String> = text
        .lines()
        .filter(|l| !l.trim_start().starts_with('#') && l.contains('='))
        .filter_map(|l| {
            let mut parts = l.splitn(2, '=');
            let k = parts.next()?.trim().to_lowercase();
            // Do NOT lowercase the value — paths are case-sensitive
            let v = parts.next()?.trim().trim_matches('"').to_string();
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
