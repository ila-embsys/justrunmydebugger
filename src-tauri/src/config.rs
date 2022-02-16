use serde::{Deserialize, Serialize};

use crate::openocd::config::Config;

#[derive(Clone, Serialize, Deserialize, Default)]
pub struct AppConfig {
    board: Config,
    interface: Config,
    target: Config,
}
