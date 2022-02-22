/// App settings container type
type state_t = AppTypes.Settings.t

/// Variant with update settings actions
module Update = {
  type t =
    | Board(option<Openocd.config_file_t>)
    | Target(option<Openocd.config_file_t>)
    | Interface(option<Openocd.config_file_t>)
    | Id(string)
    | Hostname(string)
    | All(state_t)
}

/// Update settings action type alias
type action_t = Update.t

/// Specific context for this App settings management
///
/// See ReactExt.Context.
///
module Context = {
  include ReactExt.Context.Make({
    type context = (state_t, action_t => unit)
    let defaultValue = (AppTypes.Settings.default(), _ => ())
  })
}

/// Context provider to read and write settings of the application
///
/// Should be used with hook `useSettings` to extract an initial
/// settings value and save the settings to memory.
///
/// See
/// - https://rescript-lang.org/docs/react/latest/context
/// - https://dev.to/believer/rescript-using-usecontext-in-reasonreact-19p3
module Provider = {
  /// Update app settings structure on every action
  /// Arguments:
  ///   state - previous state
  ///   action - update action
  let updater = (state: state_t, action): state_t => {
    switch action {
    | Update.Board(board) => {...state, openocd: {...state.openocd, board: board}}
    | Update.Target(target) => {...state, openocd: {...state.openocd, target: target}}
    | Update.Interface(interface) => {
        ...state,
        openocd: {...state.openocd, interface: interface},
      }
    | Update.Id(id) => {...state, gitpod: {...state.gitpod, instance_id: id}}
    | Update.Hostname(hostname) => {...state, gitpod: {...state.gitpod, hostname: hostname}}
    | Update.All(state) => state
    }
  }

  @react.component
  let make = (~children, ~initial) => {
    let (state, dispatch) = React.useReducer(updater, initial)
    <Context.Provider value=(state, dispatch)> children </Context.Provider>
  }
}
