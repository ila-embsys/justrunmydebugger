type configs_t = {configs: array<Openocd.config_file_t>}
type settings_t = {gitpod: AppTypes.gitpod_settings_t, openocd: Openocd.config_t}
type dump_state_t = {dumped: settings_t}

type config_lists_t = {
  boards: array<Openocd.config_file_t>,
  interfaces: array<Openocd.config_file_t>,
  targets: array<Openocd.config_file_t>,
}

let invoke_get_config_lists = (): Promise.t<config_lists_t> => Tauri.invoke("get_config_lists")

let invoke_start = (cfgs: configs_t): Promise.t<string> => Tauri.invoke1("start", cfgs)

let invoke_kill = (): Promise.t<string> => Tauri.invoke("kill")

let invoke_load_state = (): Promise.t<settings_t> => Tauri.invoke("load_state")

type gitpod_hostname_t = option<string>
type gitpod_config_t = {
  id: string,
  host: gitpod_hostname_t,
}

let invoke_start_gitpod = (~config: gitpod_config_t): Promise.t<string> =>
  Tauri.invoke1("start_gitpod", config)

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

/// Describe content of message of "app://notification" tauri event
module Notification = {
  module Level = {
    @deriving(jsConverter)
    type t =
      | @as(0) Info
      | @as(1) Warn
      | @as(2) Error
  }

  type t = {
    level: Level.t,
    message: string,
  }

  let codec = Jzon.object2(
    ({level, message}) => (level, message),
    ((level, message)) => {message: message, level: level}->Ok,
    Jzon.field("level", Utils.Json.Jzon.int_enum(Level.tToJs, Level.tFromJs)),
    Jzon.field("message", Jzon.string),
  )
}

/// Describe content of message of "app://openocd/event" tauri event
module OpenocdEvent = {
  module Kind = {
    @deriving(jsConverter)
    type t =
      | @as(0) Start
      | @as(1) Stop
  }

  type t = Kind.t

  let codec = Utils.Json.Jzon.int_enum(Kind.tToJs, Kind.tFromJs)
}

/// Describe content of message of "app://openocd/output" tauri event
module OpenocdOutput = {
  type t = string
  let codec = Jzon.string
}

module ReactHooks = {
  open Promise
  open Belt_Option

  /// Subscribe to event and call user callback if event is received
  ///
  /// Use `useTypedListen` to parse payload to rescript types
  let useListen = (event: string, ~callback: Tauri.event<'p> => unit) => {
    let (unlisten: option<unit => unit>, setUnlisten) = React.useState(() => None)

    let cb = React.useCallback1(callback, [])

    /* Effect: subscribe to event. Call `unsubscribe` on cleanup. */
    React.useEffect3(() => {
      if unlisten->isNone {
        Tauri.listen(~event_name=event, ~callback)
        ->then(unlisten => {
          setUnlisten(_ => unlisten)
          resolve()
        })
        ->ignore
      }

      unlisten
    }, (unlisten, event, cb))
  }

  /// Generic hook to receive "typed" events
  ///
  /// Subscribe to event and try to convert event.payload to 'a on receive
  ///
  /// Arguments:
  ///   event ??? event subscribe to
  ///   codec ?????Jzon.codec which converts JSON to 'a
  ///
  /// Returns
  ///   event structure of type 'a or None, if conversion failed
  let useTypedListen = (event: string, codec: Jzon.codec<'a>): option<'a> => {
    let (payload: option<'a>, setPayload) = React.useState(() => None)

    let makeTyped = (js_obj: 'p): option<'a> => {
      let decode_result = js_obj->Jzon.decodeWith(codec)

      switch decode_result {
      | Ok(result) => Some(result)
      | Error(e) => {
          %log.error(`Bad message payload: ${e->Jzon.DecodingError.toString}`)
          None
        }
      }
    }

    useListen(event, ~callback=e => {
      setPayload(_ => makeTyped(e.payload))
    })

    payload
  }
}
