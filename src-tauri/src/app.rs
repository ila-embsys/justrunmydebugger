use log::{error, info, warn};
use std::io::{BufRead, BufReader};
use std::{
    process::Child,
    sync::{Arc, Mutex},
};
use tauri::Window;
use threadpool::ThreadPool;

use crate::api;
use crate::{
    config::AppConfig,
    error::ErrorMsg,
    notification,
    openocd::config::{Config, ConfigsSet},
    openocd::{event as openocd_event, proc as openocd},
};

pub struct App {
    pub openocd_workers: Mutex<ThreadPool>,
    pub openocd_proc: Arc<Mutex<Option<Arc<Mutex<Child>>>>>,
}

impl App {
    pub fn new() -> Arc<Mutex<Self>> {
        Arc::new(Mutex::new(App {
            openocd_workers: Mutex::new(ThreadPool::new(1)),
            openocd_proc: Arc::new(Mutex::new(None)),
        }))
    }

    /// Start openocd as process with provided configs as args
    ///
    /// Started process emits event `openocd-output` on every received line of
    /// openocd output to stderr. Return status as a string.
    ///
    /// List of configs can be retrieved with `get_config_list`.
    ///
    /// # Arguments
    ///
    /// * `configs` — an array of `Config` to run OpenOCD with.
    /// * `state` — a tauri object for storing openocd process handler.
    /// * `window` — a tauri windows object to emit events.
    ///
    /// # Example
    ///
    /// Start `openocd -f "<script_path>/interface/stlink-v2.cfg" -f "<script_path>/target/stm32f0x.cfg"`:
    ///
    /// ```
    /// start(vec![
    ///     Board{name: "stlink-v2", path: "<script_path>/interface/stlink-v2.cfg"},
    ///     Board{name: "stm32f0x", path: "<script_path>/target/stm32f0x.cfg"},
    /// ], ...)
    /// ```
    ///
    pub fn start(&self, configs: Vec<Config>, window: Window) -> Result<String, ErrorMsg> {
        let result = self.openocd_workers.lock();
        let openocd_proc = self.openocd_proc.clone();

        if let Ok(workers) = result {
            if workers.active_count() > 0 {
                Err("OpenOCD has been already started!".into())
            } else {
                workers.execute(move || {
                    let command = openocd::start(&configs);
                    if let Some(command) = command {
                        let cmd = Arc::new(Mutex::new(command));
                        openocd_proc.lock().unwrap().replace(cmd.clone());

                        let stderr = cmd.lock().unwrap().stderr.take().unwrap();
                        let reader = BufReader::new(stderr);

                        info!("OpenOCD started!");
                        notification::send(&window, "OpenOCD started!", notification::Level::Info);
                        openocd_event::send(&window, openocd_event::Kind::Start);

                        reader
                            .lines()
                            .filter_map(|line| line.ok())
                            .for_each(|line| {
                                window
                                    .emit(
                                        "openocd-output",
                                        api::Payload {
                                            message: format!("{}\n", line),
                                        },
                                    )
                                    .unwrap_or_else(|e| {
                                        error!("Error occurred while OpenOCD running: {}", e);
                                    });

                                info!("-- {}", line);
                            });

                        warn!("OpenOCD stopped!");
                        notification::send(&window, "OpenOCD stopped!", notification::Level::Warn);
                        openocd_event::send(&window, openocd_event::Kind::Stop);
                    }
                });

                Ok("OpenOCD started!".into())
            }
        } else {
            Err("OpenOCD start failed!".into())
        }
    }

    /// Dump selected fields with configs in GUI
    ///
    /// Return string with status.
    ///
    pub fn dump_state(&self, dumped: AppConfig) -> Result<String, ErrorMsg> {
        let res = confy::store("justrunmydebugger-config", dumped);

        match res {
            Ok(_) => Ok("Config was dumped!".into()),
            Err(e) => Err(format!("Config dump failed: {}", e).into()),
        }
    }

    /// Return previously dumped fields with configs
    ///
    /// Configs contain empty name/path if their was not previously dumped.
    ///
    pub fn load_state(&self) -> AppConfig {
        let res = confy::load::<AppConfig>("justrunmydebugger-config");

        match res {
            Ok(config) => config,
            Err(_) => AppConfig::default(),
        }
    }

    /// Kill started OpenOCD process if it was started
    ///
    /// Return error string if something gone wrong.
    ///
    pub fn kill(&self, window: Window) -> Result<String, ErrorMsg> {
        let res = self.openocd_proc.lock().unwrap().as_ref().and_then(|proc| {
            if proc.lock().unwrap().kill().is_err() {
                error!("OpenOCD was not killed!");
                Some("OpenOCD was not killed!")
            } else {
                info!("OpenOCD killed.");
                None
            }
        });

        match res {
            Some(err) => Err(err.into()),
            None => {
                openocd_event::send(&window, openocd_event::Kind::Stop);
                Ok("OpenOCD stopped".into())
            }
        }
    }

    /// Return a struct with three lists of `Config`
    ///
    /// Read cfg files in the script folder of OpenOCD and return them
    /// as three list of `Config { name, path }`: boards, interfaces and targets.
    /// Return empty vector if configs was not found.
    ///
    pub fn get_config_lists(&self) -> Result<ConfigsSet, ErrorMsg> {
        ConfigsSet::new().map_err(|s| ErrorMsg { message: s })
    }
}
