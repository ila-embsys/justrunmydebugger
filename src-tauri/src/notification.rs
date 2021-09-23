use tauri::Window;

use crate::api;

#[derive(Clone, serde::Serialize)]
pub enum Level {
    Info,
    Warn,
    Error,
}

#[derive(Clone, serde::Serialize)]
pub struct Notification {
    pub level: Level,
    pub message: String,
}

pub fn send(window: &Window, msg: &str, lvl: Level) {
    window
        .emit(
            "event",
            api::Payload {
                message: serde_json::to_string(&Notification {
                    level: lvl,
                    message: msg.into(),
                })
                .expect("Fail to serialize event!"),
            },
        )
        .expect("Fail to send event!");
}
