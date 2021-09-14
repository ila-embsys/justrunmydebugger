use serde::{Deserialize, Serialize};

use crate::openocd::config::Config;

#[derive(Clone, Serialize, Deserialize)]
pub struct AppConfig {
    board: Config,
    interface: Config,
    target: Config,
}

impl ::std::default::Default for AppConfig {
    fn default() -> Self {
        Self {
            board: Config::default(),
            interface: Config::default(),
            target: Config::default(),
        }
    }
}
