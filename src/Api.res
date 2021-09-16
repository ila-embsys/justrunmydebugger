type configs = {configs: array<Openocd.config_t>}
type config_type = {configType: string}
type dump_state_t = {dumped: Openocd.app_config_t}

type config_lists_t = {
  boards: array<Openocd.config_t>,
  interfaces: array<Openocd.config_t>,
  targets: array<Openocd.config_t>,
}

let invoke_get_config_lists = (): Promise.t<config_lists_t> => Tauri.invoke("get_config_lists")

let invoke_start = (cfgs: configs): Promise.t<string> => Tauri.invoke1("start", cfgs)

let invoke_kill = (): Promise.t<string> => Tauri.invoke("kill")

let invoke_load_state = (): Promise.t<Openocd.app_config_t> => Tauri.invoke("load_state")

let invoke_dump_state = (state: dump_state_t): Promise.t<string> =>
  Tauri.invoke1("dump_state", state)

/// Try to extract error msg from Promise exception
///
/// Backend must return a error type witch looks like a Js exception that is
/// having a `message` field. Otherwise message can't be extracted.
let promise_error_msg = (error: 'a): string => {
  let error_stringified = Js.Json.stringifyAny(error)->Belt.Option.getWithDefault("unknown")

  switch error {
  | Promise.JsError(obj) =>
    switch Js.Exn.message(obj) {
    | Some(msg) => msg
    | None => `Some unknown error: ${error_stringified}`
    }
  | _ => `Some unknown error: ${error_stringified}`
  }
}
