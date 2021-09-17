type config_set_t = {
  board: option<Openocd.config_t>,
  interface: option<Openocd.config_t>,
  target: option<Openocd.config_t>,
}
