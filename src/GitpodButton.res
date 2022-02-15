/// Type of field filled in
type fill_t =
  | Id(string)
  | Host(string)

/// Actions to switch state
type action_t =
  | Init
  | Fill(fill_t)
  | Connect
  | Success
  | Fail(string)
  | Cancel

/// Actual state of component
type current_state_t =
  | Waiting
  | Connecting
  | Fail
  | Done

/// Component state container
type state_t = {
  current_state: current_state_t,
  tooltip_message: string,
  is_dialog_opened: bool,
  tooltip_icon: React.element,
  error_msg: string,
  id: string,
  hostname: string,
}

/// Initial state
let default_state: state_t = {
  current_state: Waiting,
  is_dialog_opened: false,
  tooltip_message: "Connect to Gitpod",
  tooltip_icon: <MuiIcon.Cloud.Normal />,
  error_msg: "",
  id: "",
  hostname: "",
}

/// FAB style
let fab_style = ReactDOM.Style.make(
  ~position="fixed",
  ~bottom="40px",
  ~right="20px",
  ~top="auto",
  ~left="auto",
  ~margin="0",
  (),
)

/// Switch between states
let reducer = (state: state_t, action: action_t) => {
  switch action {
  | Init => {...state, is_dialog_opened: true}
  | Connect =>
    if state.current_state != Connecting || state.id->Utils.String.empty {
      {
        ...state,
        current_state: Connecting,
        tooltip_message: "Connecting...",
        tooltip_icon: <Mui.CircularProgress size={Mui.CircularProgress.Size.int(30)} />,
        is_dialog_opened: true,
        error_msg: "",
      }
    } else {
      state
    }
  | Fill(input) =>
    switch input {
    | Id(s) => {...state, current_state: Waiting, id: s}
    | Host(s) => {...state, current_state: Waiting, hostname: s}
    }
  | Success => {
      ...state,
      current_state: Done,
      tooltip_message: "Connected to Gitpod",
      tooltip_icon: <MuiIcon.Cloud.Success />,
      is_dialog_opened: false,
      error_msg: default_state.error_msg,
    }
  | Fail(error_msg) => {
      ...state,
      current_state: Fail,
      tooltip_message: "Try again",
      tooltip_icon: <MuiIcon.Cloud.Fail />,
      error_msg: error_msg,
    }
  | Cancel => {...state, is_dialog_opened: false}
  }
}

/// GitpodButton component
@react.component
let make = () => {
  open Mui
  open Promise

  let (state, dispatch) = React.useReducer(reducer, default_state)

  /* Invoke Gitpod connection process */
  React.useEffect1(() => {
    if state.current_state == Connecting {
      Js.Console.info2("Connecting... with id", state.id)

      let hostname = if state.hostname->Js.String2.length > 0 {
        Some(state.hostname)
      } else {
        None
      }

      Api.invoke_start_gitpod(~config={id: state.id, host: hostname})
      ->then(s => {
        %log.info(
          "Connection result:"
          ("=>", s)
        )

        dispatch(Success)
        resolve()
      })
      ->catch(err => {
        %log.error(
          "Starting Gitpod companion error:"
          ("Api.promise_error_msg(err)", Api.promise_error_msg(err))
        )

        dispatch(Fail(Api.promise_error_msg(err)))
        resolve()
      })
      ->ignore

      None
    } else {
      None
    }
  }, [state.current_state])

  /* Render */
  <>
    <Tooltip title={state.tooltip_message->React.string} arrow=true placement=#left>
      <Fab color=#default style=fab_style onClick={_ => dispatch(Init)}> state.tooltip_icon </Fab>
    </Tooltip>
    <Dialog \"open"={state.is_dialog_opened} maxWidth=Dialog.MaxWidth.xs>
      <DialogTitle> {"Gitpod connect"->React.string} </DialogTitle>
      <DialogContent>
        <DialogContentText>
          {"Fill info below to connect to run Gitpod instance."->React.string}
        </DialogContentText>
        <TextField
          id="id"
          label={"Instance ID"->React.string}
          required=true
          value={state.id->TextField.Value.string}
          onChange={e => Fill(Id(e->Utils.Event.value))->dispatch}
          fullWidth=true
          margin=#none
          variant=#standard
        />
        <br />
        <TextField
          id="hostname"
          label={"Hostname"->React.string}
          value={state.hostname->TextField.Value.string}
          onChange={e => Fill(Host(e->Utils.Event.value))->dispatch}
          fullWidth=true
          margin=#none
          variant=#standard
        />
        <FormHelperText error={state.current_state == Fail} margin=#dense>
          {state.error_msg->React.string}
        </FormHelperText>
      </DialogContent>
      <DialogActions>
        <Button onClick={_ => dispatch(Cancel)}> {"Close"->React.string} </Button>
        <MuiExt.LoadingButton
          text="Connect"
          onClick={() => dispatch(Connect)}
          disabled={state.id->Utils.String.empty || state.current_state == Connecting}
          loading={state.current_state == Connecting}
        />
      </DialogActions>
    </Dialog>
  </>
}
