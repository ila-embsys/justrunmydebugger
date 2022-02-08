use tauri::Window;

#[derive(Clone, serde::Serialize)]
pub struct Output {
    pub line: String,
}

pub fn send(window: &Window, line: String) {
    crate::api::send_raw(window, "openocd.output", Output { line });
}
