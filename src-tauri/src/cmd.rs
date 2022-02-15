use log::info;
use tauri::Window;

use crate::config::AppConfig;
use crate::error::ErrorMsg;
use crate::openocd::config::{Config, ConfigsSet};
use crate::state::State;

/// Return a struct with three lists of `Config`
///
/// Read cfg files in the script folder of OpenOCD and return them
/// as three list of `Config { name, path }`: boards, interfaces and targets.
/// Return empty vector if configs was not found.
///
#[tauri::command]
pub fn get_config_lists(state: tauri::State<State>) -> Result<ConfigsSet, ErrorMsg> {
    state.app.lock().unwrap().get_config_lists()
}

/// Kill started OpenOCD process if it was started
///
/// Return error string if something gone wrong.
///
#[tauri::command]
pub fn kill(state: tauri::State<State>, window: Window) -> Result<String, ErrorMsg> {
    state.app.lock().unwrap().kill(&window)
}

/// Start Gitpod companion
///
/// Return error string if something gone wrong.
///
#[tauri::command]
pub fn start_gitpod(
    id: String,
    host: Option<String>,
    state: tauri::State<State>,
    window: Window,
) -> Result<String, ErrorMsg> {
    state.app.lock().unwrap().start_gitpod(id, host, window)
}

/// Start openocd as process with provided configs as args
///
/// Started process emits event `openocd.output` on every received line of
/// openocd output to stderr. Return status as a string.
///
/// List of configs can be retrieved with `get_config_list`.
///
/// # Arguments
///
/// * `configs` — an array of `Config` to run OpenOCD with.
/// * `state` — a tauri object for storing openocd process handler.
/// * `window` — a tauri windows object to emit events.
///
/// # Example
///
/// Start `openocd -f "<script_path>/interface/stlink-v2.cfg" -f "<script_path>/target/stm32f0x.cfg"`:
///
/// ```
/// start(vec![
///     Board{name: "stlink-v2", path: "<script_path>/interface/stlink-v2.cfg"},
///     Board{name: "stm32f0x", path: "<script_path>/target/stm32f0x.cfg"},
/// ], ...)
/// ```
///
#[tauri::command]
pub fn start(
    configs: Vec<Config>,
    state: tauri::State<State>,
    window: Window,
) -> Result<String, ErrorMsg> {
    info!(
        r#"Start openocd with configs: "{:?}""#,
        configs
            .clone()
            .into_iter()
            .map(|config| { config.path })
            .collect::<Vec<String>>()
    );

    state.app.lock().unwrap().start(configs, window)
}

/// Dump selected fields with configs in GUI
///
/// Return string with status.
///
#[tauri::command]
pub fn dump_state(state: tauri::State<State>, dumped: AppConfig) -> Result<String, ErrorMsg> {
    state.app.lock().unwrap().dump_state(dumped)
}

/// Return previously dumped fields with configs
///
/// Configs contain empty name/path if their was not previously dumped.
///
#[tauri::command]
pub fn load_state(state: tauri::State<State>) -> AppConfig {
    state.app.lock().unwrap().load_state()
}
