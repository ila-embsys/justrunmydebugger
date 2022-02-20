let useNotification = (enqueueSnackbar) => {
  (~msg: string, ~level: Notistack.VariantType.t) => {
    let _ = enqueueSnackbar(
      ~message=msg->React.string,
      ~options=Some({...Notistack.OptionsObject.default, variant: Some(level)}),
    )
  }
}

/// GitpodButton component
@react.component
let make = () => {
  open Mui
  open Promise
  open Gitpod_State

  let (state, dispatch) = React.useReducer(Gitpod.State.reducer, Gitpod.State.initial_state)
  let (instance_id, setInstanceId) = React.useState(() => "")
  let (hostname, setHostname) = React.useState(() => "")
  let {enqueueSnackbar, _} = Notistack.useSnackbar()
  let sendNotification = useNotification(enqueueSnackbar)

  /* Invoke Gitpod connection process */
  React.useEffect1(() => {
    if state.current_state == Connecting {
      Js.Console.info2("Connecting... with id", instance_id)

      Api.invoke_start_gitpod(~config={id: instance_id, host: hostname->Utils.String.to_option})
      ->then(s => {
        %log.info(
          "Connected successfully!"
          ("Result", s)
        )

        dispatch(Success)
        sendNotification(~msg=s, ~level=#success)
        resolve()
      })
      ->catch(err => {
        %log.error(
          "Starting Gitpod companion error:"
          ("Error", Api.promise_error_msg(err))
        )

        dispatch(Fail(Api.promise_error_msg(err)))
        resolve()
      })
      ->ignore
    }

    None
  }, [state.current_state])

  /* Render */
  <>
    // Render flying button
    <Tooltip title={state.tooltip_message->React.string} arrow=true placement=#left>
      <Gitpod.Fab onClick={() => dispatch(Init)} icon=state.fab_icon />
    </Tooltip>
    // Render dialog
    <Dialog \"open"={state.is_dialog_opened} maxWidth=Dialog.MaxWidth.xs>
      <DialogTitle> {"Gitpod connect"->React.string} </DialogTitle>
      <DialogContent>
        <DialogContentText>
          {"Fill info below to connect to run Gitpod instance."->React.string}
        </DialogContentText>
        <Gitpod.TextField
          id="id"
          label="Instance ID"
          value=instance_id
          required=true
          onChange={id => setInstanceId(_ => id)}
        />
        <br />
        <Gitpod.TextField
          id="hostname" label="Hostname" value=hostname onChange={h => setHostname(_ => h)}
        />
        <FormHelperText error={state.current_state == Fail} margin=#dense>
          {state.error_msg->React.string}
        </FormHelperText>
      </DialogContent>
      <DialogActions>
        <Button onClick={_ => dispatch(Close)}> {"Close"->React.string} </Button>
        <MuiExt.LoadingButton
          text="Connect"
          onClick={() => dispatch(Connect({id: instance_id, host: hostname}))}
          disabled={instance_id->Utils.String.empty || state.current_state == Connecting}
          loading={state.current_state == Connecting}
        />
      </DialogActions>
    </Dialog>
  </>
}
