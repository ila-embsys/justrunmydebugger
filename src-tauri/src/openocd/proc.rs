use std::option::Option;
use std::process::{Child, Command, Stdio};
use which::which;

use crate::openocd::config::Config;

pub fn is_available() -> bool {
    which("openocd").is_ok()
}

pub fn start(config: &[Config]) -> Option<Child> {
    if is_available() {
        let args = config
            .iter()
            .map(|config| ["-f", config.path.as_str()])
            .flatten()
            .collect::<Vec<&str>>();

        let thread = Command::new("openocd")
            .args(args)
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
