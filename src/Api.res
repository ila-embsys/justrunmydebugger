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

/// Describe content of message of "notification" tauri event
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

/// Describe content of message of "openocd.event" tauri event
module OpenocdEvent = {
  module Kind = {
    @deriving(jsConverter)
    type t =
      | @as(0) Start
      | @as(1) Stop
  }

  type t = {event: Kind.t}

  let codec = Jzon.object1(
    ({event}) => event,
    event => {event: event}->Ok,
    Jzon.field("event", Utils.Json.Jzon.int_enum(Kind.tToJs, Kind.tFromJs)),
  )
}

/// Describe content of message of "openocd.output" tauri event
module OpenocdOutput = {
  type t = {line: string}

  let codec = Jzon.object1(
    ({line}) => line,
    line => {line: line}->Ok,
    Jzon.field("line", Jzon.string),
  )
}

module ReactHooks = {
  open Promise
  open Belt_Option

  /// Subscribe to event and call user callback if event is received
  ///
  /// Use `useTypedListen` to parse payload to rescript types
  let useListen = (event: string, ~callback: Tauri.event => unit) => {
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
  /// Subscribe to event and try to convert event.payload.message to 'a on receive
  ///
  /// Arguments:
  ///   event — event subscribe to
  ///   codec — Jzon.codec which converts JSON to 'a
  ///
  /// Returns
  ///   event structure of type 'a or None, if conversion failed
  let useTypedListen = (event: string, codec: Jzon.codec<'a>): option<'a> => {
    let (payload: option<'a>, setPayload) = React.useState(() => None)

    let makeTyped = (js_obj: Js.Json.t): option<'a> => {
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
