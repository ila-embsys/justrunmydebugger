type gitpod_settings_t = {
  instance_id: string,
  hostname: string,
}

module Settings = {
  type t = {openocd: Openocd.config_set_t, gitpod: gitpod_settings_t}

  let default = (): t => {
    {
      openocd: {
        board: None,
        interface: None,
        target: None,
      },
      gitpod: {instance_id: "", hostname: ""},
    }
  }
}
