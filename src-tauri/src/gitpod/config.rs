use serde::{Deserialize, Serialize};

#[derive(Clone, Serialize, Deserialize, Default)]
pub struct Config {
    instance_id: String,
    hostname: String,
}
