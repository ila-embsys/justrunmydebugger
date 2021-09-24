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
///   config_set_t: config set
///   config_set_t => unit: setter for config set
///
let useDumpedState = (): (config_set_t, config_set_t => unit) => {
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
      Js.Console.info2("Dump selectors state:", conf_to_save)
      resolve()
    })
    ->catch(err => {
      Js.Console.error(Api.promise_error_msg(err))
      resolve()
    })
    ->ignore
  }

  /* Effect: load the last saved configs once */
  React.useEffect1(() => {
    invoke_load_state()
    ->then((conf: Openocd.app_config_t) => {
      Js.Console.info2("Load selectors state:", conf)

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
    ->catch(err => {
      Js.Console.error(Api.promise_error_msg(err))
      resolve()
    })
    ->ignore

    None
  }, [])

  (config_set, dump_state)
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

  /* Effect: receive config lists */
  React.useEffect1(() => {
    invoke_get_config_lists()
    ->then(lists => {
      setConfigLists(_ => lists)
      resolve()
    })
    ->catch(err => {
      Js.Console.error(Api.promise_error_msg(err))
      resolve()
    })
    ->ignore
    None
  }, [])

  config_lists
}

/// Subscribe to `notification` event and return notification_t object on event receive
let useOpenocdNotification = (): option<Api.notification_t> => {
  // Convert JSON string to Api.notification_t
  let toNotification = (json_string: string): option<Api.notification_t> => {
    let json = Utils.Json.parse(json_string)

    switch json {
    | Some(json) => {
        let decode_result = json->Jzon.decodeWith(Api.Codecs.notification)

        switch decode_result {
        | Ok(result) => Some(result)
        | Error(e) => {
            Js.Console.error(`Bad notification message: ${e->Jzon.DecodingError.toString}`)
            None
          }
        }
      }
    | _ => None
    }
  }

  // Subscribe to event
  let notification = Api.ReactHooks.useTypedListen("notification", toNotification)

  notification
}
