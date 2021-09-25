use serde::Serialize;

#[derive(Clone, Serialize)]
pub struct Payload {
    pub message: String,
}
