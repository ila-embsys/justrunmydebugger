use log::error;
use serde::Serialize;

pub fn send_raw<T: Serialize>(window: &tauri::Window, event: &str, payload: T) {
    window.emit(event, payload).unwrap_or_else(|e| {
        error!("Error occurred while sending event: {}", e);
    });
}
