use ratatui::style::Color;
use std::collections::HashMap;
use std::env;
use std::fs;
use std::path::PathBuf;

// ─────────────────────────────────────────────────────────────────────────────
// Parsed configuration loaded from tui.conf at startup
// ─────────────────────────────────────────────────────────────────────────────

pub struct Config {
    pub accent_color:      Color,
    pub footer_color:      Color,
    pub note_border_color: Color,
    pub note_cursor_bg:    Color,
    pub workspace_root:    PathBuf,
}

impl Default for Config {
    fn default() -> Self {
        Config {
            accent_color:      Color::Cyan,
            footer_color:      Color::DarkGray,
            note_border_color: Color::Yellow,
            note_cursor_bg:    Color::Yellow,
            workspace_root:    find_workspace_root(),
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
    // 2. Walk up from binary path
    if let Ok(exe) = env::current_exe() {
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

fn conf_path() -> PathBuf {
    // Look next to the binary first, then fall back to cwd
    if let Ok(exe) = env::current_exe() {
        let candidate = exe.parent().unwrap_or(&exe).join("tui.conf");
        if candidate.exists() { return candidate; }
    }
    PathBuf::from("tui.conf")
}

pub fn load() -> Config {
    let mut cfg = Config::default();
    let path = conf_path();
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

    pick_color!(accent_color,      "accent_color");
    pick_color!(footer_color,      "footer_color");
    pick_color!(note_border_color, "note_border_color");
    pick_color!(note_cursor_bg,    "note_cursor_bg");

    if let Some(v) = pairs.get("workspace_root") {
        let p = PathBuf::from(v);
        if p.is_dir() {
            cfg.workspace_root = p;
        }
    }

    cfg
}
