type config_t = {
  name: string,
  path: string,
}

type app_config_t = {
  board: config_t,
  interface: config_t,
  target: config_t,
}
