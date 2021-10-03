use std::sync::Arc;
use std::sync::Mutex;

use crate::app::App;

pub struct State {
    pub app: Arc<Mutex<App>>
}
