#[allow(unused_imports)]
use regex::Regex;
use serde::{Deserialize, Serialize};
use std::convert::TryFrom;
use std::option::Option;
use std::path::{Path, PathBuf};
use walkdir::WalkDir;

#[allow(unused_imports)]
use crate::openocd::proc::start_exec;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub name: String,
    pub path: String,
}

impl ::std::default::Default for Config {
    fn default() -> Self {
        Self {
            name: "".into(),
            path: "".into(),
        }
    }
}

struct ConfigFileName {
    name: String,
}

impl TryFrom<&Path> for ConfigFileName {
    type Error = ();

    fn try_from(path: &Path) -> Result<Self, Self::Error> {
        let config_file = path
            .extension()
            .and_then(|ext| ext.to_str())
            .and_then(|ext| {
                if ext.ends_with("cfg") {
                    let path = path.to_string_lossy().to_owned();
                    let ext_with_dot = format!("{}{}", ".", &ext);
                    let path_without_ext: String = path
                        .to_string()
                        .strip_suffix(&ext_with_dot)
                        .expect(
                            "Any relative path to file must end with the same file \
                             extension as his absolute parent.",
                        )
                        .into();

                    Some(ConfigFileName {
                        name: path_without_ext,
                    })
                } else {
                    None
                }
            });

        config_file.ok_or(())
    }
}

fn extract_configs_from(configs_dir: &Path) -> Option<Vec<Config>> {
    if configs_dir.is_dir() {
        let root_iter = WalkDir::new(configs_dir)
            .contents_first(true)
            .into_iter()
            .flatten();

        Some(
            root_iter
                .map(|entry| {
                    let path = entry.path().to_path_buf();
                    let relative_path = path
                        .strip_prefix(configs_dir)
                        .expect("configs_dir must be a parent of it's own entries by design.");

                    let config = ConfigFileName::try_from(relative_path);
                    if let Ok(config) = config {
                        Some(Config {
                            name: config.name,
                            path: entry.path().display().to_string(),
                        })
                    } else {
                        None
                    }
                })
                .flatten()
                .collect::<Vec<Config>>(),
        )
    } else {
        None
    }
}

struct OpenocdPaths {
    board: PathBuf,
    target: PathBuf,
    interface: PathBuf,
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
        // Try to find openocd executable
        let binary = which::which("openocd");
        if let Ok(binary) = binary {
            // Get root of openocd
            let root = Self::from_bin_to_root(binary.as_path())?;

            // If we got an unexpected root we should try harder (see else branch)
            if Self::validate_root(root.as_path()) {
                Some(root)
            } else {
                // Try to extract a real path to binary by hacking openocd (see `hack_binary_path`)
                let true_binary = Self::hack_binary_path(binary.as_path())?;
                let true_root = Self::from_bin_to_root(true_binary.as_path())?;
                if Self::validate_root(true_root.as_path()) {
                    Some(true_root)
                } else {
                    // Just give up...
                    None
                }
            }
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
            .filter_map(|entry| {
                let name = entry.path().file_name()?.to_string_lossy().to_string();
                if name == "scripts" {
                    Some(entry)
                } else {
                    None
                }
            });

        Some(root_iter.next()?.into_path())
    }

    #[allow(dead_code)]
    fn validate_root(root: &Path) -> bool {
        Self::scripts(root).is_some()
    }

    #[allow(dead_code)]
    fn from_bin_to_root(bin: &Path) -> Option<PathBuf> {
        Some(bin.parent()?.parent()?.to_owned())
    }
}

#[derive(Serialize)]
pub struct ConfigsSet {
    boards: Vec<Config>,
    interfaces: Vec<Config>,
    targets: Vec<Config>,
}

impl ConfigsSet {
    pub fn new() -> Result<ConfigsSet, String> {
        let paths = OpenocdPaths::new();
        paths.map(|paths| ConfigsSet {
            boards: Self::extract_configs(paths.board.as_path()),
            interfaces: Self::extract_configs(paths.interface.as_path()),
            targets: Self::extract_configs(paths.target.as_path()),
        })
    }

    fn extract_configs(path: &Path) -> Vec<Config> {
        extract_configs_from(path).map_or(Vec::<Config>::new(), |cfgs| cfgs)
    }
}
