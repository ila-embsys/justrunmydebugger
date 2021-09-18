open AppTypes

/// Subscribe to `openocd-output` and return OpenOCD output as string
///
/// Returns:
///   output: output of OpenOCD
///   setOutput: setter to force set internal state
///
let useOpenocdOutput = (): (string, string => unit) => {
  let (output: string, setOutput) = React.useState(() => "")

  /* Cut and append OpenOCD output to state by `openocd-output` event */
  let openocd_output_cb = (e: Tauri.event) => {
    let message = e.payload.message

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

    setOutput(output => {
      (output ++ message)->text_cuter(5000)
    })
  }

  Api.ReactHooks.useListen("openocd-output", ~callback=openocd_output_cb)

  (output, string => {setOutput(_ => string)})
}

/// Load state the last saved app state, dump state, update state
///
/// Store and provide access to config_set (set of current selected configs).
///
/// Returns:
///   appState: config set
///   setAppState: setter for config set
///
let useAppState = (): (config_set_t, config_set_t => unit) => {
  open Api
  open Promise

  /* App state (config set) */
  let (config_set: config_set_t, setConfigSet) = React.useState(() => {
    board: None,
    interface: None,
    target: None,
  })

  /* Dump an app state (config set) */
  let dump_state = (config_set: config_set_t) => {
    setConfigSet(_ => config_set)

    let option_to_empty_cfg = (conf: option<Openocd.config_t>) => {
      switch conf {
      | Some(c) => c
      | None => {name: "", path: ""}
      }
    }

    let conf_to_save: Openocd.app_config_t = {
      board: config_set.board->option_to_empty_cfg,
      interface: config_set.interface->option_to_empty_cfg,
      target: config_set.target->option_to_empty_cfg,
    }

    invoke_dump_state({dumped: conf_to_save})
    ->then(_ => {
      Js.Console.log("Dump selectors state")
      Js.Console.log(conf_to_save)
      resolve()
    })
    ->ignore
  }

  /* Effect: load the last saved configs once */
  React.useEffect1(() => {
    invoke_load_state()
    ->then((conf: Openocd.app_config_t) => {
      Js.Console.log("Load selectors state")
      Js.Console.log(conf)

      /* Turn empty config to option */
      let as_option = (conf: Openocd.config_t) => {
        if conf.name != "" {
          Some(conf)
        } else {
          None
        }
      }

      setConfigSet(_ => {
        board: conf.board->as_option,
        interface: conf.interface->as_option,
        target: conf.target->as_option,
      })
      resolve()
    })
    ->ignore

    None
  }, [])

  (config_set, dump_state)
}