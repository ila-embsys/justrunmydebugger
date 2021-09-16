@module("@tauri-apps/api/tauri")
external invoke: string => Promise.t<'data> = "invoke"

@module("@tauri-apps/api/tauri")
external invoke1: (string, 'a) => Promise.t<'data> = "invoke"

@module("@tauri-apps/api/tauri")
external invoke2: (string, 'a, 'b) => Promise.t<'data> = "invoke"

@module("@tauri-apps/api/tauri")
external invoke3: (string, 'a, 'b, 'c) => Promise.t<'data> = "invoke"

type payload = {message: string}
type event = {name: string, payload: payload}

@module("@tauri-apps/api/event")
external listen: (~event_name: string, ~callback: event => unit) => Promise.t<'event> = "listen"
