use log::{error, info, warn};
use std::io::{BufRead, BufReader};
use std::sync::{Arc, Mutex};
use tauri::Window;

use crate::openocd;
use crate::openocd::Config;
use crate::openocd::ConfigType;
use crate::state::State;
use std::str::FromStr;

#[derive(Clone, serde::Serialize)]
struct OpenocdOutput {
    message: String,
}

#[tauri::command]
#[deprecated(note = r#"Use `get_config_list` cmd with "BOARD" argument instead."#)]
pub fn get_board_list() -> Vec<Config> {
    let empty = Vec::<Config>::new();

    if openocd::is_avaliable() {
        let boards = openocd::get_configs(ConfigType::BOARD);
        boards.map_or(empty, |boards| boards)
    } else {
        warn!("OpenOCD not found!");
        empty
    }
}

#[tauri::command]
pub fn get_config_list(config_type: String) -> Vec<Config> {
    let empty = Vec::<Config>::new();

    if openocd::is_avaliable() {
        match ConfigType::from_str(config_type.as_str()) {
            Ok(board_type) => {
                let boards = openocd::get_configs(board_type);
                boards.map_or(empty, |boards| boards)
            }
            Err(_) => {
                error!("Bad config type!");
                empty.clone()
            }
        }
    } else {
        warn!("OpenOCD not found!");
        empty
    }
}

#[tauri::command]
pub fn kill(state: tauri::State<State>) -> String {
    let res = state
        .openocd_proc
        .lock()
        .unwrap()
        .as_ref()
        .and_then(|proc| {
            if let Err(_) = proc.lock().unwrap().kill() {
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

#[tauri::command]
#[deprecated(note = "Use `start` cmd with `vec![config]` argument instead.")]
pub fn start_for_config(config: Config, state: tauri::State<State>, window: Window) -> String {
    start(vec![config], state, window)
}

#[tauri::command]
pub fn start(config: Vec<Config>, state: tauri::State<State>, window: Window) -> String {
    info!(
        r#"Start openocd with configs: "{:?}""#,
        config
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
                let command = openocd::start_as_process(&config);
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
