use command_group::AsyncGroupChild;
use gitpod_ports_backwarder::{run_companion, run_ssh, CompanionHandle, HostName};
use std::result::Result;
use tokio::runtime::Runtime;

use crate::error::ErrorMsg;

pub struct Handlers {
    pub companion: CompanionHandle,
    pub ssh: AsyncGroupChild,
}

pub fn start(instance_id: String, hostname: Option<String>) -> Result<Handlers, ErrorMsg> {
    let runtime = Runtime::new().unwrap();
    let hostname = hostname.map_or(HostName::Default, HostName::Is);

    runtime
        .block_on(run_companion(hostname))
        .ok_or_else(|| "Can't start Gitpod companion executable!".into())
        .and_then(|handle| {
            let ports = vec![3333];
            let ssh_handle = run_ssh(&handle.ssh_config_path, &instance_id, ports);
            runtime
                .block_on(ssh_handle)
                .ok_or_else(|| "Can't start SSH executable!".into())
                .map(|ssh| Handlers {
                    companion: handle,
                    ssh,
                })
        })
}
