use tauri::Window;

use crate::api;

#[derive(Clone, serde_repr::Serialize_repr, serde_repr::Deserialize_repr)]
#[repr(u8)]
pub enum Level {
    Info = 0,
    Warn = 1,
    Error = 2,
}

#[derive(Clone, serde::Serialize)]
pub struct Notification {
    pub level: Level,
    pub message: String,
}

pub fn send(window: &Window, msg: &str, lvl: Level) {
    api::send_raw(
        window,
        "notification",
        Notification {
            level: lvl,
            message: msg.into(),
        },
    );
}
