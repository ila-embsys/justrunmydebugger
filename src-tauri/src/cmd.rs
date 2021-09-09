use log::{error, info, warn};
use std::io::{BufRead, BufReader};
use std::sync::{Arc, Mutex};
use tauri::Window;

use crate::openocd::config::{get_configs, Config, ConfigType};
use crate::openocd::proc as openocd;
use crate::state::State;
use std::str::FromStr;

#[derive(Clone, serde::Serialize)]
struct OpenocdOutput {
    message: String,
}

/// Return a list of `Config` of board configs
///
/// Same as `get_config_list` but return only one type of configs.
/// Return empty list if configs was not found.
///
#[tauri::command]
#[deprecated(note = r#"Use `get_config_list` cmd with "BOARD" argument instead."#)]
pub fn get_board_list() -> Vec<Config> {
    let empty = Vec::<Config>::new();

    if openocd::is_available() {
        let boards = get_configs(ConfigType::BOARD);
        boards.map_or(empty, |boards| boards)
    } else {
        warn!("OpenOCD not found!");
        empty
    }
}

/// Returns a list of `Config` of selected type
///
/// Read cfg files in the script folder of OpenOCD and return them
/// as list of `Config { name, path }`. Return empty vector if configs
/// was not found.
///
/// # Arguments
///
/// * `config_type` - A string with possible values: BOARD, INTERFACE, TARGET
///
#[tauri::command]
pub fn get_config_list(config_type: String) -> Vec<Config> {
    let empty = Vec::<Config>::new();

    if openocd::is_available() {
        match ConfigType::from_str(config_type.as_str()) {
            Ok(board_type) => {
                let boards = get_configs(board_type);
                boards.map_or(empty, |boards| boards)
            }
            Err(_) => {
                error!("Bad config type!");
                empty
            }
        }
    } else {
        warn!("OpenOCD not found!");
        empty
    }
}

/// Kill started OpenOCD process if it was started
///
/// Return error string if something gone wrong.
///
#[tauri::command]
pub fn kill(state: tauri::State<State>) -> String {
    let res = state
        .openocd_proc
        .lock()
        .unwrap()
        .as_ref()
        .and_then(|proc| {
            if proc.lock().unwrap().kill().is_err() {
                error!("OpenOCD was not killed!");
                Some("OpenOCD was not killed!")
            } else {
                info!("OpenOCD killed.");
                None
            }
        });

    match res {
        Some(err) => err.into(),
        None => "".into(),
    }
}

/// Same as `start` but only for one config as OpenOCD argument
///
/// See `start` docs.
#[tauri::command]
#[deprecated(note = "Use `start` cmd with `vec![config]` argument instead.")]
pub fn start_for_config(config: Config, state: tauri::State<State>, window: Window) -> String {
    start(vec![config], state, window)
}

/// Start openocd as process with provided configs as args
///
/// Started process emits event `openocd-output` on every received line of
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
pub fn start(configs: Vec<Config>, state: tauri::State<State>, window: Window) -> String {
    info!(
        r#"Start openocd with configs: "{:?}""#,
        configs
            .clone()
            .into_iter()
            .map(|config| { config.path })
            .collect::<Vec<String>>()
    );

    let result = state.openocd_workers.lock();

    let openocd_proc = state.openocd_proc.clone();

    if let Ok(workers) = result {
        if workers.active_count() > 0 {
            "OpenOCD has been already started!".into()
        } else {
            workers.execute(move || {
                let command = openocd::start(&configs);
                if let Some(command) = command {
                    let cmd = Arc::new(Mutex::new(command));
                    openocd_proc.lock().unwrap().replace(cmd.clone());

                    let stderr = cmd.lock().unwrap().stderr.take().unwrap();
                    let reader = BufReader::new(stderr);

                    info!("OpenOCD started!");
                    reader
                        .lines()
                        .filter_map(|line| line.ok())
                        .for_each(|line| {
                            window
                                .emit(
                                    "openocd-output",
                                    OpenocdOutput {
                                        message: format!("{}\n", line),
                                    },
                                )
                                .unwrap();
                            info!("-- {}", line);
                        });
                    warn!("OpenOCD stopped!");
                }
            });

            "OpenOCD started!".into()
        }
    } else {
        "OpenOCD start failed!".into()
    }
}
