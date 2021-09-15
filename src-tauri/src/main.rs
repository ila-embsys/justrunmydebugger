#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

use std::sync::Arc;
use std::sync::Mutex;
use threadpool::ThreadPool;

mod cmd;
mod config;
mod openocd;
mod state;

fn main() {
    ::std::env::set_var("RUST_LOG", "debug");
    env_logger::init();

    tauri::Builder::default()
        .manage(state::State {
            openocd_workers: Mutex::new(ThreadPool::new(1)),
            openocd_proc: Arc::new(Mutex::new(None)),
        })
        // This is where you pass in your commands
        .invoke_handler(tauri::generate_handler![
            cmd::get_config_list,
            cmd::start,
            cmd::kill,
            cmd::load_state,
            cmd::dump_state,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
