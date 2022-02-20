@react.component
let make = () => {
  let openocdNotification = AppHooks.useNotification()
  let {enqueueSnackbar, _} = Notistack.useSnackbar()

  React.useEffect1(() => {
    switch openocdNotification {
    | Some(notification) => {
        let convert_msg_level = switch notification.level {
        | Api.Notification.Level.Info => #info
        | Api.Notification.Level.Error => #error
        | Api.Notification.Level.Warn => #warning
        }

        let _ = enqueueSnackbar(
          ~message=notification.message->React.string,
          ~options=Some({...Notistack.OptionsObject.default, variant: Some(convert_msg_level)}),
        )
        None
      }
    | None => None
    }
  }, [openocdNotification])

  <> </>
}
