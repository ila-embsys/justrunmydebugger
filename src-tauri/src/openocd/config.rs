use crate::openocd::paths::OpenocdPaths;
use serde::{Deserialize, Serialize};
use std::convert::TryFrom;
use std::path::Path;
use walkdir::WalkDir;

struct ConfigFileName {
    name: String,
}

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
        Self::extract_configs_from(path).map_or(Vec::<Config>::new(), |cfgs| cfgs)
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

                        let config_name = ConfigFileName::try_from(relative_path);
                        if let Ok(config_name) = config_name {
                            Some(Config {
                                name: config_name.name,
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
}
