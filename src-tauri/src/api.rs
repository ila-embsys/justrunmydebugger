use log::error;
use serde::Serialize;

pub trait TauriEvent {
    fn topic(&self) -> &'static str;

    fn send_to(self, window: &tauri::Window)
    where
        Self: Sized + Serialize + Clone,
    {
        window.emit(self.topic(), self).unwrap_or_else(|e| {
            error!("Error occurred while sending event: {}", e);
        });
    }
}
