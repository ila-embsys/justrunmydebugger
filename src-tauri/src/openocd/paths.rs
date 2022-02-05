use lazy_static::lazy_static;
use std::collections::HashSet;
use std::option::Option;
use std::path::{Path, PathBuf};
use walkdir::WalkDir;

#[cfg_attr(unix, allow(unused_imports))]
use regex::Regex;

#[cfg_attr(unix, allow(unused_imports))]
use crate::openocd::proc::start_exec;

pub struct OpenocdPaths {
    pub board: PathBuf,
    pub target: PathBuf,
    pub interface: PathBuf,
}

impl OpenocdPaths {
    pub fn new() -> Result<OpenocdPaths, String> {
        let paths = Self::root()
            .and_then(|root| Self::scripts(root.as_path()))
            .map(|scripts| OpenocdPaths {
                board: Self::board(scripts.as_path()),
                target: Self::target(scripts.as_path()),
                interface: Self::interface(scripts.as_path()),
            });

        paths.ok_or_else(|| "OpenOCD not found!".into())
    }

    fn board(script: &Path) -> PathBuf {
        script.join("board")
    }

    fn interface(script: &Path) -> PathBuf {
        script.join("interface")
    }

    fn target(script: &Path) -> PathBuf {
        script.join("target")
    }

    /// Extract path to a real openocd binary through executing it with a wrong argument
    #[cfg(target_os = "windows")]
    fn hack_binary_path(binary: &Path) -> Option<PathBuf> {
        // Run openocd with a non existing flag
        let output = start_exec(binary, vec!["--bad_flag".into()])?;

        // Path to binary always locates near ": unknown option" string
        let path_regex = Regex::new(r"(?P<path>.+): unknown option").ok();
        let path = path_regex?.captures(&output)?.name("path")?.as_str();

        Some(PathBuf::from(path))
    }

    #[cfg(target_os = "windows")]
    fn root() -> Option<PathBuf> {
        let binary = which::which("openocd");
        if let Ok(binary) = binary {
            let true_binary = Self::hack_binary_path(binary.as_path())?;
            let true_root = Self::from_bin_to_root(true_binary.as_path())?;
            Some(true_root)
        } else {
            None
        }
    }

    #[cfg(target_os = "linux")]
    fn root() -> Option<PathBuf> {
        let unix_path_1 = PathBuf::from("/usr/local/share/openocd");
        let unix_path_2 = PathBuf::from("/usr/share/openocd");

        if unix_path_1.exists() {
            Some(unix_path_1)
        } else if unix_path_2.exists() {
            Some(unix_path_2)
        } else {
            None
        }
    }

    fn scripts(openocd_path: &Path) -> Option<PathBuf> {
        let mut root_iter = WalkDir::new(openocd_path)
            .into_iter()
            .flatten()
            .filter(|entry| entry.path().is_dir())
            .filter_map(|scripts| {
                let dir_name = scripts.path().file_name()?.to_string_lossy().to_string();
                if dir_name == "scripts" && Self::validate_scripts(scripts.path()) {
                    Some(scripts)
                } else {
                    None
                }
            });

        Some(root_iter.next()?.into_path())
    }

    #[cfg_attr(unix, allow(dead_code))]
    fn validate_scripts(scripts: &Path) -> bool {
        lazy_static! {
            static ref REQUIRED_DIRS: HashSet<String> = vec!["board", "interface", "target"]
                .into_iter()
                .map(String::from)
                .collect();
        }

        let found_dirs: HashSet<String> = WalkDir::new(scripts)
            .max_depth(1)
            .into_iter()
            .flatten()
            .filter(|entry| entry.path().is_dir())
            .filter_map(|dir: walkdir::DirEntry| {
                let dir_name = dir.path().file_name()?.to_string_lossy().to_string();

                if REQUIRED_DIRS.contains(&dir_name) {
                    Some(dir_name)
                } else {
                    None
                }
            })
            .collect();

        found_dirs == *REQUIRED_DIRS
    }

    #[cfg_attr(unix, allow(dead_code))]
    fn from_bin_to_root(bin: &Path) -> Option<PathBuf> {
        Some(bin.parent()?.parent()?.to_owned())
    }
}
