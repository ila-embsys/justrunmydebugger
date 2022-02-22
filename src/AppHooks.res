open AppTypes

/// Subscribe to `app://openocd/output` and return OpenOCD output as string
///
/// Returns:
///   output: output of OpenOCD
///   setOutput: setter to force set internal state
///
let useOpenocdOutput = (): (string, string => unit) => {
  let (output: string, setOutput) = React.useState(() => "")
  let line = Api.ReactHooks.useTypedListen("app://openocd/output", Api.OpenocdOutput.codec)

  /* Cut and append OpenOCD output to state by `app://openocd/output` event */
  React.useEffect1(() => {
    let rec text_cuter = (text: string, length: int) => {
      if text->Js.String2.length > length {
        let second_line_position = text->Js.String2.indexOf("\n") + 1

        if second_line_position == -1 {
          text
        } else {
          let substring = text->Js.String2.substr(~from=second_line_position)
          text_cuter(substring, length)
        }
      } else {
        text
      }
    }

    let line = switch line {
    | Some(line) => line
    | None => ""
    }

    setOutput(output => {
      (output ++ line)->text_cuter(5000)
    })

    None
  }, [line])

  (output, string => {setOutput(_ => string)})
}

/// Receive config lists
///
/// Returns:
///     config_lists_t — received config lists
///
let useConfigLists = () => {
  open Api
  open Promise

  let (config_lists: config_lists_t, setConfigLists) = React.useState(() => {
    boards: [],
    interfaces: [],
    targets: [],
  })

  let (is_configs_found, setConfigsFound) = React.useState(() => false)

  /* Effect: receive config lists */
  React.useEffect1(() => {
    invoke_get_config_lists()
    ->then(lists => {
      setConfigLists(_ => lists)
      setConfigsFound(_ => true)
      resolve()
    })
    ->catch(err => {
      %log.error(
        "Exception raised on Effect: receive config lists"
        ("Api.promise_error_msg(err)", Api.promise_error_msg(err))
      )
      resolve()
    })
    ->ignore
    None
  }, [])

  (is_configs_found, config_lists)
}

/// Load the last app settings, dump settings, update settings
///
/// Store and provide access to app settings.
///
/// Returns:
///   Settings.t: the app settings
///   Settings.t => unit: setter for the settings
///
let useSettings = (): (option<Settings.t>, Settings.t => unit) => {
  open Api
  open Promise

  /* Setting state */
  let (settings: option<Settings.t>, setSettings) = React.useState(() => {
    None
  })

  /* Dump an app settings */
  let dump_settings = (settings: Settings.t) => {
    setSettings(_ => Some(settings))

    let option_to_empty_cfg = (conf: option<Openocd.config_file_t>) => {
      switch conf {
      | Some(c) => c
      | None => {name: "", path: ""}
      }
    }

    let openocd_config: Openocd.openocd_config_t = {
      board: settings.openocd.board->option_to_empty_cfg,
      interface: settings.openocd.interface->option_to_empty_cfg,
      target: settings.openocd.target->option_to_empty_cfg,
    }

    invoke_dump_state({dumped: {gitpod: settings.gitpod, openocd: openocd_config}})
    ->then(_ => {
      Js.Console.info2("Dump app settings:", settings)
      resolve()
    })
    ->catch(err => {
      %log.error(
        "Dump selectors state raise an exception"
        ("Api.promise_error_msg(err)", Api.promise_error_msg(err))
      )
      resolve()
    })
    ->ignore
  }

  /* Effect: load the last saved settings once */
  React.useEffect1(() => {
    invoke_load_state()
    ->then((settings: settings_t) => {
      Js.Console.info2("Load app settings:", settings)

      /* Turn empty config to option */
      let as_option = (conf: Openocd.config_file_t) => {
        if conf.name != "" {
          Some(conf)
        } else {
          None
        }
      }

      setSettings(_ => Some({
        openocd: {
          board: settings.openocd.board->as_option,
          interface: settings.openocd.interface->as_option,
          target: settings.openocd.target->as_option,
        },
        gitpod: settings.gitpod,
      }))

      resolve()
    })
    ->catch(err => {
      %log.error(
        "Load selectors state raise an exception"
        ("Api.promise_error_msg(err)", Api.promise_error_msg(err))
      )
      resolve()
    })
    ->ignore

    None
  }, [])

  (settings, dump_settings)
}

/// Subscribe to `app://notification` event and return Notification.t object on event receive
let useNotification = (): option<Api.Notification.t> => {
  Api.ReactHooks.useTypedListen("app://notification", Api.Notification.codec)
}

/// Subscribe to `openocd.event` event and return OpenocdEvent.t object on event receive
let useOpenocdEvent = (): option<Api.OpenocdEvent.t> => {
  Api.ReactHooks.useTypedListen("app://openocd/event", Api.OpenocdEvent.codec)
}
