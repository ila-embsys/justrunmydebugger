use command_group::AsyncGroupChild;
use log::{error, info, warn};
use std::cell::Cell;
use std::io::{BufRead, BufReader};
use std::{
    process::Child,
    sync::{Arc, Mutex},
};
use tauri::Window;
use threadpool::ThreadPool;

use crate::api::TauriEvent;
use crate::{
    config::AppConfig,
    error::ErrorMsg,
    gitpod, notification, openocd,
    openocd::config::{Config, ConfigsSet},
};

pub struct App {
    pub openocd_workers: ThreadPool,
    pub openocd_proc: Arc<Mutex<Option<Arc<Mutex<Child>>>>>,
    pub gitpod_handlers: Cell<Option<AsyncGroupChild>>,
}

impl App {
    pub fn new() -> Arc<Mutex<Self>> {
        Arc::new(Mutex::new(App {
            openocd_workers: ThreadPool::new(1),
            openocd_proc: Arc::new(Mutex::new(None)),
            gitpod_handlers: Cell::new(None),
        }))
    }

    /// Start openocd as process with provided configs as args
    ///
    /// Started process emits event `openocd.output` on every received line of
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
        if self.openocd_workers.active_count() > 0 {
            Err("OpenOCD has been already started!".into())
        } else {
            self.start_openocd(configs, window);
            Ok("OpenOCD started!".into())
        }
    }

    pub fn start_gitpod(
        &mut self,
        instance_id: String,
        host: Option<String>,
        window: Window,
    ) -> Result<String, ErrorMsg> {
        match self.gitpod_handlers.get_mut() {
            Some(_) => {
                notification::Notification::info("Restart Gitpod companion...".into())
                    .send_to(&window);
                // kill
                gitpod::events::Event::Stop.send_to(&window);
                self.gitpod_handlers
                    .replace(gitpod::proc::start(instance_id, host));
            }
            None => {
                self.gitpod_handlers
                    .replace(gitpod::proc::start(instance_id, host));
            }
        }

        gitpod::events::Event::Start.send_to(&window);

        Ok("Gitpod started!".into())
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
    pub fn kill(&self, window: &Window) -> Result<String, ErrorMsg> {
        let res: Option<&str> = self.openocd_proc.lock().unwrap().as_mut().and_then(|proc| {
            if !openocd::proc::kill_proc(&mut proc.lock().unwrap()) {
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
                openocd::events::Event::Stop.send_to(window);
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

    fn start_openocd(&self, configs: Vec<Config>, window: Window) {
        let openocd_proc = self.openocd_proc.clone();

        self.openocd_workers.execute(move || {
            let command = openocd::proc::start(&configs);

            if let Some(command) = command {
                let cmd = Arc::new(Mutex::new(command));
                openocd_proc.lock().unwrap().replace(cmd.clone());

                let stderr = cmd.lock().unwrap().stderr.take().unwrap();
                let reader = BufReader::new(stderr);

                App::send_event(&window, openocd::events::Event::Start, None);

                reader
                    .lines()
                    .filter_map(|line| line.ok())
                    .for_each(|line| {
                        format!("{}\n", line).send_to(&window);
                        info!("-- {}", line);
                    });

                App::send_event(&window, openocd::events::Event::Stop, None)
            } else {
                App::send_event(
                    &window,
                    openocd::events::Event::Stop,
                    Some("OpenOCD was not started!"),
                )
            }
        });
    }

    fn send_event(window: &Window, event: openocd::events::Event, msg: Option<&str>) {
        type Event = openocd::events::Event;
        match event {
            Event::Start => {
                let msg = msg.map_or("OpenOCD started!", |s| s);
                info!("{}", msg);
                notification::Notification::info(msg.into()).send_to(window);
            }
            Event::Stop => {
                let msg = msg.map_or("OpenOCD stopped!", |s| s);
                warn!("{}", msg);
                notification::Notification::warn(msg.into()).send_to(window);
            }
        }
        event.send_to(window);
    }
}
