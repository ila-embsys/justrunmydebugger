use crate::api::TauriEvent;

#[derive(Clone, serde_repr::Serialize_repr)]
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

impl Notification {
    #[allow(dead_code)]
    pub fn info(msg: String) -> Self {
        Self {
            message: msg,
            level: Level::Info,
        }
    }

    #[allow(dead_code)]
    pub fn warn(msg: String) -> Self {
        Self {
            message: msg,
            level: Level::Warn,
        }
    }

    #[allow(dead_code)]
    pub fn error(msg: String) -> Self {
        Self {
            message: msg,
            level: Level::Error,
        }
    }
}

impl TauriEvent for Notification {
    fn topic(&self) -> &'static str {
        "app://notification"
    }
}
