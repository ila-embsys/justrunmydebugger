type config_file_t = {
  name: string,
  path: string,
}

type openocd_config_set_t = {
  board: option<config_file_t>,
  interface: option<config_file_t>,
  target: option<config_file_t>,
}

type openocd_config_t = {
  board: config_file_t,
  interface: config_file_t,
  target: config_file_t,
}
