#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

use std::io::{BufRead, BufReader};
use std::process::Child;
use std::sync::Arc;
use std::sync::Mutex;
use tauri::Window;
use threadpool::ThreadPool;

mod openocd;

struct State {
    openocd_workers: Mutex<ThreadPool>,
    openocd_proc: Arc<Mutex<Option<Arc<Mutex<Child>>>>>,
}

#[derive(Clone, serde::Serialize)]
struct OpenocdOutput {
    message: String,
}

fn main() {
    tauri::Builder::default()
        .manage(State {
            openocd_workers: Mutex::new(ThreadPool::new(1)),
            openocd_proc: Arc::new(Mutex::new(None)),
        })
        // This is where you pass in your commands
        .invoke_handler(tauri::generate_handler![
            get_board_list,
            start_for_config,
            kill
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

#[tauri::command]
fn get_board_list() -> Vec<openocd::Config> {
    let empty = Vec::<openocd::Config>::new();

    if let Some(openocd_path) = openocd::root_path() {
        let board_path = openocd::board_path(openocd_path);
        let boards = openocd::get_configs(&board_path);

        match boards {
            Some(boards) => boards,
            None => empty,
        }
    } else {
        println!("OpenOCD not found!");
        empty
    }
}

#[tauri::command]
fn kill(state: tauri::State<State>) -> String {
    let res = state
        .openocd_proc
        .lock()
        .unwrap()
        .as_ref()
        .and_then(|proc| {
            if let Err(_) = proc.lock().unwrap().kill() {
                Some("OpenOCD was not killed!")
            } else {
                None
            }
        });

    match res {
        Some(err) => err.into(),
        None => "".into(),
    }
}

#[tauri::command]
fn start_for_config(config: openocd::Config, state: tauri::State<State>, window: Window) -> String {
    println!("The user has desired to run \"{}\" board", config.name);
    let result = state.openocd_workers.lock();

    let openocd_proc = state.openocd_proc.clone();

    if let Ok(workers) = result {
        if workers.active_count() > 0 {
            "OpenOCD has been already started!".into()
        } else {
            workers.execute(move || {
                let command = openocd::start_in_thread(config);
                if let Some(command) = command {
                    let cmd = Arc::new(Mutex::new(command));
                    openocd_proc.lock().unwrap().replace(cmd.clone());

                    let stderr = cmd.lock().unwrap().stderr.take().unwrap();
                    let reader = BufReader::new(stderr);

                    reader
                        .lines()
                        .filter_map(|line| line.ok())
                        .for_each(|line| {
                            window
                                .emit(
                                    "openocd-output",
                                    OpenocdOutput {
                                        message: line.clone(),
                                    },
                                )
                                .unwrap();
                            println!("-- {}", line);
                        });
                }
            });

            "OpenOCD started!".into()
        }
    } else {
        "OpenOCD start failed!".into()
    }
}
