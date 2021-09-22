use regex::Regex;
use serde::{Deserialize, Serialize};
use std::convert::TryFrom;
use std::option::Option;
use std::path::{Path, PathBuf};
use walkdir::WalkDir;

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

/// Extract path to a real openocd binary through executing it with a wrong argument
fn hack_binary_path(binary: &Path) -> Option<PathBuf> {
    // Run openocd with a non existing flag
    let output = start_exec(binary, vec!["--bad_flag".into()])?;

    // Path to binary always locates near ": unknown option" string
    let path_regex = Regex::new(r"(?P<path>.+): unknown option").ok();
    let path = path_regex?.captures(&output)?.name("path")?.as_str();

    Some(PathBuf::from(path))
}

#[cfg(target_os = "windows")]
pub fn root_path() -> Option<PathBuf> {
    let from_bin_to_root =
        |bin: &Path| -> Option<PathBuf> { Some(bin.parent()?.parent()?.to_owned()) };

    let validate_root = |root: &Path| scripts_path(root).is_dir();

    // Try to find openocd executable
    let binary = which::which("openocd");
    if let Ok(binary) = binary {
        // Get root of openocd
        let root = from_bin_to_root(binary.as_path())?;

        // If we got an unexpected root we should try harder (see else branch)
        if validate_root(root.as_path()) {
            Some(root)
        } else {
            // Try to extract a real path to binary by hacking openocd (see `hack_binary_path`)
            let binary = hack_binary_path(binary.as_path())?;
            let root = from_bin_to_root(binary.as_path())?;
            if validate_root(root.as_path()) {
                Some(root)
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
pub fn root_path() -> Option<PathBuf> {
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

pub fn scripts_path(openocd_path: &Path) -> PathBuf {
    openocd_path.join("scripts")
}

pub fn board_path(openocd_path: &Path) -> PathBuf {
    scripts_path(openocd_path).join("board")
}

pub fn interface_path(openocd_path: &Path) -> PathBuf {
    scripts_path(openocd_path).join("interface")
}

pub fn target_path(openocd_path: &Path) -> PathBuf {
    scripts_path(openocd_path).join("target")
}

#[derive(Serialize)]
pub struct ConfigsSet {
    boards: Vec<Config>,
    interfaces: Vec<Config>,
    targets: Vec<Config>,
}

impl ConfigsSet {
    pub fn new() -> Result<ConfigsSet, String> {
        let root = root_path();
        if let Some(root) = root {
            Ok(ConfigsSet {
                boards: ConfigsSet::extract_configs(board_path(&root).as_path()),
                interfaces: ConfigsSet::extract_configs(interface_path(&root).as_path()),
                targets: ConfigsSet::extract_configs(target_path(&root).as_path()),
            })
        } else {
            Err("OpenOCD not found!".into())
        }
    }

    fn extract_configs(path: &Path) -> Vec<Config> {
        extract_configs_from(path).map_or(Vec::<Config>::new(), |cfgs| cfgs)
    }
}
