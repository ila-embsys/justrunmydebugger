#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

use std::sync::Mutex;
use std::{io::Read, sync::Arc};
use tauri::Window;
use threadpool::ThreadPool;

mod openocd;

struct State {
    openocd_workers: Mutex<ThreadPool>,
}

#[derive(Clone, serde::Serialize)]
struct OpenocdOutput {
    message: String,
}

fn main() {
    tauri::Builder::default()
        .manage(State {
            openocd_workers: Mutex::new(ThreadPool::new(1)),
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
fn kill(window: Window) {
    window
        .emit("kill-openocd", OpenocdOutput { message: "".into() })
        .unwrap();
}

#[tauri::command]
fn start_for_config(config: openocd::Config, state: tauri::State<State>, window: Window) -> String {
    println!("The user has desired to run \"{}\" board", config.name);
    let result = state.openocd_workers.lock();

    if let Ok(workers) = result {
        if workers.active_count() > 0 {
            "OpenOCD has been already started!".into()
        } else {
            workers.execute(move || {
                let command = openocd::start_in_thread(config);
                if let Some(command) = command {
                    let cmd = Arc::new(Mutex::new(command));
                    let cmd_to_be_killed = cmd.clone();

                    window.listen("kill-openocd", move |_| {
                        let _ = cmd_to_be_killed.lock().unwrap().kill();
                    });

                    let mut stdout = cmd.lock().unwrap().stdout.take().unwrap();
                    loop {
                        let mut openocd_output = String::new();
                        let read_size = stdout.read_to_string(&mut openocd_output);
                        if read_size.is_ok() && !openocd_output.is_empty() {
                            window
                                .emit(
                                    "openocd-output",
                                    OpenocdOutput {
                                        message: openocd_output,
                                    },
                                )
                                .unwrap();
                        }

                        std::thread::sleep(std::time::Duration::from_millis(500))
                    }
                }
            });

            "OpenOCD started!".into()
        }
    } else {
        "OpenOCD start failed!".into()
    }
}
