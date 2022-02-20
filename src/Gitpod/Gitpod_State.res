/// Required info to connect to Gitpod
type connection_info_t = {
  id: string,
  host: string,
}

/// Actions to switch state
type action_t =
  | Init
  | Connect(connection_info_t)
  | Success
  | Fail(string)
  | Close

/// Actual state of component
type current_t =
  | Waiting
  | Connecting
  | Fail
  | Done

/// Component state container
type t = {
  current_state: current_t,
  tooltip_message: string,
  is_dialog_opened: bool,
  fab_icon: Gitpod_Fab.Icon.t,
  error_msg: string,
}

let initial_state: t = {
  current_state: Waiting,
  is_dialog_opened: false,
  tooltip_message: "Connect to Gitpod",
  fab_icon: Gitpod_Fab.Icon.Normal,
  error_msg: "",
}

/// Switch between states
let reducer = (state: t, action: action_t) => {
  switch action {
  | Init => {...state, is_dialog_opened: true}
  | Connect(info) =>
    if state.current_state != Connecting || info.id->Utils.String.empty {
      {
        current_state: Connecting,
        tooltip_message: "Connecting...",
        fab_icon: Gitpod_Fab.Icon.Loading,
        is_dialog_opened: true,
        error_msg: initial_state.error_msg,
      }
    } else {
      state
    }
  | Success => {
      current_state: Done,
      tooltip_message: "Connected to Gitpod",
      fab_icon: Gitpod_Fab.Icon.Success,
      is_dialog_opened: false,
      error_msg: initial_state.error_msg,
    }
  | Fail(error_msg) => {
      current_state: Fail,
      tooltip_message: "Try again",
      is_dialog_opened: true,
      fab_icon: Gitpod_Fab.Icon.Fail,
      error_msg: error_msg,
    }
  | Close => {...state, is_dialog_opened: false}
  }
}
