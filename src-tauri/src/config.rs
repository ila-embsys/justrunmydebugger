use serde::{Deserialize, Serialize};

use crate::gitpod::config::Config as GitpodConfig;
use crate::openocd::config::Config as OpenocdConfig;

#[derive(Clone, Serialize, Deserialize, Default)]
pub struct OpenocdConfigSet {
    board: OpenocdConfig,
    interface: OpenocdConfig,
    target: OpenocdConfig,
}

#[derive(Clone, Serialize, Deserialize, Default)]
pub struct AppConfig {
    openocd: OpenocdConfigSet,
    gitpod: GitpodConfig,
}
