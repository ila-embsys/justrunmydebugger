use log::error;
use serde::Serialize;

#[derive(Clone, Serialize)]
pub struct Payload {
    pub message: String,
}

pub fn send_raw(window: &tauri::Window, event: &str, msg: &str) {
    window
        .emit(
            event,
            Payload {
                message: msg.to_string(),
            },
        )
        .unwrap_or_else(|e| {
            error!("Error occurred while sending event: {}", e);
        });
}
