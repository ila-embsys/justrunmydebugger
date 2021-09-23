use tauri::Window;

use crate::api;

#[derive(Clone, serde::Serialize)]
pub enum Kind {
    Start,
    Stop,
}

#[derive(Clone, serde::Serialize)]
pub struct Event {
    pub event: Kind,
}

pub fn send(window: &Window, event: Kind) {
    window
        .emit(
            "event",
            api::Payload {
                message: serde_json::to_string(&Event { event }).expect("Fail to serialize event!"),
            },
        )
        .expect("Fail to send event!");
}
