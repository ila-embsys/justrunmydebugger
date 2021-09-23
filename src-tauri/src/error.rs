use serde::Serialize;

#[derive(Clone, Serialize)]
pub struct ErrorMsg {
    pub message: String,
}

impl ErrorMsg {
    fn new(msg: &str) -> Self {
        Self { message: msg.into() }
    }
}

impl From<&str> for ErrorMsg {
    fn from(msg: &str) -> ErrorMsg {
        ErrorMsg::new(msg)
    }
}

impl From<String> for ErrorMsg {
    fn from(msg: String) -> ErrorMsg {
        ErrorMsg::new(&msg)
    }
}
