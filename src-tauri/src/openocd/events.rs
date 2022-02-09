use crate::api::TauriEvent;

#[derive(Clone, Copy, serde_repr::Serialize_repr)]
#[repr(u8)]
pub enum Event {
    Start = 0,
    Stop = 1,
}

impl TauriEvent for String {
    fn topic(&self) -> &'static str {
        "openocd.output"
    }
}

impl TauriEvent for Event {
    fn topic(&self) -> &'static str {
        "openocd.event"
    }
}
