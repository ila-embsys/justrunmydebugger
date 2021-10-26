use std::convert::TryInto;
use std::option::Option;
use std::path::Path;
use std::process::{Child, Command, Stdio};
use std::result::Result;
use sysinfo::{ProcessExt, Signal, System, SystemExt};
use which::which;

use crate::openocd::config::Config;

pub fn is_available() -> bool {
    which("openocd").is_ok()
}

#[cfg(target_os = "linux")]
fn spawn(args: Vec<&str>) -> Result<Child, std::io::Error> {
    Command::new("openocd")
        .args(args)
        .stderr(Stdio::piped())
        .spawn()
}

#[cfg(target_os = "windows")]
fn spawn(args: Vec<&str>) -> Result<Child, std::io::Error> {
    use std::os::windows::process::CommandExt;
    use winapi::um::winbase::CREATE_NO_WINDOW;

    Command::new("openocd")
        .creation_flags(CREATE_NO_WINDOW)
        .args(args)
        .stderr(Stdio::piped())
        .spawn()
}

pub fn start(config: &[Config]) -> Option<Child> {
    if is_available() {
        let args = config
            .iter()
            .map(|config| ["-f", config.path.as_str()])
            .flatten()
            .collect::<Vec<&str>>();

        let thread = spawn(args);
        if let Ok(thread) = thread {
            Some(thread)
        } else {
            None
        }
    } else {
        None
    }
}

#[cfg_attr(unix, allow(dead_code))]
pub fn start_exec(exe_path: &Path, args: Vec<String>) -> Option<String> {
    let out = Command::new(exe_path).args(args).output();

    match out {
        Ok(out) => Some(String::from_utf8_lossy(&out.stderr).to_string()),
        Err(_) => None,
    }
}

pub fn kill_proc(proc: &mut Child) -> bool {
    // Convert all PIDs to unix format
    let openocd_pid: i32 = proc.id().try_into().unwrap();

    let mut system = System::new();
    system.refresh_all();

    // Shims could start openocd proc as a separate child-process.
    // Try to find the tree and kill the child process.
    for process in system.processes().values() {
        if process.name().contains("openocd") {
            if let Some(parent_pid) = process.parent() {
                // Convert all PIDs to unix format
                let parent_pid: i32 = parent_pid.try_into().unwrap();

                if parent_pid == openocd_pid {
                    return process.kill(Signal::Kill);
                }
            }
        }
    }

    // Otherwise just kill the process
    proc.kill().is_err()
}
