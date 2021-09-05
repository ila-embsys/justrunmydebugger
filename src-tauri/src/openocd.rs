use serde::{Deserialize, Serialize};
use std::fs::{self, DirEntry};
use std::option::Option;
use std::path::{Path, PathBuf};
use std::process::{Child, Command, Stdio};
use which::which;
use strum_macros::EnumString;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub name: String,
    pub path: String,
}

struct ConfigFile {
    name: String,
    ext: String,
}

#[derive(EnumString)]
pub enum ConfigType {
    BOARD,
    INTERFACE,
    TARGET,
}

pub fn get_configs(config_type: ConfigType) -> Option<Vec<Config>> {
    if let Some(openocd_path) = root_path() {
        let path = match config_type {
            ConfigType::BOARD => board_path(openocd_path),
            ConfigType::INTERFACE => interface_path(openocd_path),
            ConfigType::TARGET => target_path(openocd_path),
        };

        extract_configs_from(path.as_path())
    } else {
        None
    }
}

fn parse_config_name(dir_entry: &DirEntry) -> Option<ConfigFile> {
    let path = dir_entry.path();

    path.extension()?.to_str().and_then(|ext| {
        ext.ends_with("cfg").then(|| {
            let file_name = path.file_name().unwrap().to_string_lossy().to_owned();

            ConfigFile {
                name: String::from(file_name),
                ext: String::from(ext),
            }
        })
    })
}

fn extract_configs_from(configs_dir: &Path) -> Option<Vec<Config>> {
    if configs_dir.is_dir() {
        let files = fs::read_dir(&configs_dir);
        let mut board_names = Vec::<Config>::new();

        if let Ok(files) = files {
            for file_or_dir in files.into_iter() {
                if let Ok(file_or_dir) = file_or_dir {
                    let config = parse_config_name(&file_or_dir);

                    if let Some(config) = config {
                        let ext_with_dot = format!("{}{}", ".", config.ext);
                        let board_name = config.name.strip_suffix(&ext_with_dot)?;

                        board_names.push(Config {
                            name: String::from(board_name),
                            path: file_or_dir.path().display().to_string(),
                        });
                    }
                }
            }
        }

        Some(board_names)
    } else {
        None
    }
}

pub fn is_avaliable() -> bool {
    which("openocd").is_ok()
}

#[cfg(target_os = "windows")]
pub fn root_path() -> Option<PathBuf> {
    let binary = which("openocd");
    if let Ok(binary) = binary {
        Some(binary.parent()?.parent()?.to_owned())
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

pub fn scripts_path(openocd_path: PathBuf) -> PathBuf {
    openocd_path.join("scripts")
}

pub fn board_path(openocd_path: PathBuf) -> PathBuf {
    scripts_path(openocd_path).join("board")
}

pub fn interface_path(openocd_path: PathBuf) -> PathBuf {
    scripts_path(openocd_path).join("interface")
}

pub fn target_path(openocd_path: PathBuf) -> PathBuf {
    scripts_path(openocd_path).join("taget")
}

pub fn start_as_process(config: Config) -> Option<Child> {
    if is_avaliable() {
        let thread = Command::new("openocd")
            .arg("-f")
            .arg(config.path)
            .stderr(Stdio::piped())
            .spawn();

        if let Ok(thread) = thread {
            Some(thread)
        } else {
            None
        }
    } else {
        None
    }
}
