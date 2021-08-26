#![cfg_attr(
  all(not(debug_assertions), target_os = "windows"),
  windows_subsystem = "windows"
)]

mod openocd;

fn main() {
  println!("Message from Rust");

  tauri::Builder::default()
    // This is where you pass in your commands
    .invoke_handler(tauri::generate_handler![my_custom_command])
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}

#[tauri::command]
fn my_custom_command() -> Vec<openocd::Config> {
  let openocd_path = openocd::root_path();

  if let Some(openocd_path) = openocd_path {
    let board_path = openocd::board_path(openocd_path);
    let boards = openocd::get_configs(&board_path);
    println!("{:?}", boards);

    match boards {
      None => Vec::new(),
      Some(boards) => {
        println!("{:?}", boards);
        boards
      }
    }
  } else {
    println!("OpenOCD not found!");
    Vec::new()
  }
}
