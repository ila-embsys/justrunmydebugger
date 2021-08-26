use serde::Serialize;
use std::fs::{self, DirEntry};
use std::option::Option;
use std::path::{Path, PathBuf};
use which::which;

#[derive(Debug, Serialize)]
pub struct Config {
    name: String,
    path: String,
}

struct ConfigFile {
    name: String,
    ext: String,
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

pub fn get_configs(configs_dir: &Path) -> Option<Vec<Config>> {
    if configs_dir.is_dir() {
        let files = fs::read_dir(configs_dir);
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

pub fn root_path() -> Option<PathBuf> {
    let binary = which("openocd");
    if let Ok(binary) = binary {
        Some(binary.parent()?.parent()?.to_owned())
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
