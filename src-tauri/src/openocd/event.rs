use tauri::Window;

use crate::api;

#[derive(Clone, serde_repr::Serialize_repr, serde_repr::Deserialize_repr)]
#[repr(u8)]
pub enum Kind {
    Start = 0,
    Stop = 1,
}

#[derive(Clone, serde::Serialize)]
pub struct Event {
    pub event: Kind,
}

pub fn send(window: &Window, event: Kind) {
    api::send_raw(
        window,
        "openocd-event",
        serde_json::to_string(&Event { event })
            .expect("Fail to serialize event!")
            .as_str(),
    );
}
