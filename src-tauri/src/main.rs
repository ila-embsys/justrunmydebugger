#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

mod openocd;

fn main() {
    tauri::Builder::default()
        // This is where you pass in your commands
        .invoke_handler(tauri::generate_handler![
            my_custom_command,
            start_for_config
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

#[tauri::command]
fn my_custom_command() -> Vec<openocd::Config> {
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
fn start_for_config(config: openocd::Config) -> String {
    openocd::start(config)
}
