#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

mod api;
mod app;
mod cmd;
mod config;
mod error;
mod notification;
mod openocd;
mod state;

use crate::app::App;

fn main() {
    ::std::env::set_var("RUST_LOG", "debug");
    env_logger::init();

    tauri::Builder::default()
        .manage(state::State {
            app: App::new(),
        })
        // This is where you pass in your commands
        .invoke_handler(tauri::generate_handler![
            cmd::start,
            cmd::kill,
            cmd::load_state,
            cmd::dump_state,
            cmd::get_config_lists,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
