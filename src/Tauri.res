@module("@tauri-apps/api/tauri")
external invoke: string => Promise.t<'data> = "invoke"

@module("@tauri-apps/api/tauri")
external invoke1: (string, 'a) => Promise.t<'data> = "invoke"

type event<'p> = {name: string, payload: 'p}

@module("@tauri-apps/api/event")
external listen: (~event_name: string, ~callback: event<'p> => unit) => Promise.t<'event> = "listen"
