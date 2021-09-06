use std::process::Child;
use std::sync::Arc;
use std::sync::Mutex;
use threadpool::ThreadPool;

pub struct State {
    pub openocd_workers: Mutex<ThreadPool>,
    pub openocd_proc: Arc<Mutex<Option<Arc<Mutex<Child>>>>>,
}
