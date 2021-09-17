open Api

type config_set_t = {
  board: option<Openocd.config_t>,
  interface: option<Openocd.config_t>,
  target: option<Openocd.config_t>,
}

module Hooks = {
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
  /// Returns:
  ///   appState: config set
  ///   setAppState: setter for config set
  ///
  let useAppState = (): (config_set_t, config_set_t => unit) => {
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
}

@react.component
let make = () => {
  open Promise
  open MaterialUi

  let (appState, setAppState) = Hooks.useAppState()

  let (config_lists: config_lists_t, setConfigLists) = React.useState(() => {
    boards: [],
    interfaces: [],
    targets: [],
  })

  let (is_started, set_is_started) = React.useState(() => false)

  let (tab_panel_index, setTabPanelIndex) = React.useState(() => 0)

  let (openocd_output, set_openocd_output) = Hooks.useOpenocdOutput()

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

  /* Start OpenOCD process on backend with selected configs */
  let start = (~with_interface: bool) => {
    open Belt_Array
    open Belt_Option

    let unwrap_configs = (configs: array<option<Openocd.config_t>>) => {
      configs->reduce([], (arr, el) => {
        switch el {
        | Some(el) => concat(arr, [el])
        | None => arr
        }
      })
    }

    let configs = if with_interface {
      [appState.interface, appState.target]
    } else {
      [appState.board]
    }

    if configs->every(c => c->isSome) {
      set_openocd_output("")

      invoke_start({
        configs: configs->unwrap_configs,
      })
      ->then(ret => {
        Js.Console.log(`Invoking OpenOCD return: ${ret}`)
        resolve()
      })
      ->ignore

      set_is_started(_ => true)
    }
  }

  /* Stop OpenOCD */
  let kill = () => {
    invoke_kill()
    ->then(ret => {
      Js.Console.log(`Killing OpenOCD return: ${ret}`)
      resolve()
    })
    ->ignore

    set_is_started(_ => false)
  }

  let handleTabPanelChange = (_, newValue: MaterialUi_Types.any) => {
    setTabPanelIndex(newValue->MaterialUi_Types.anyUnpack)
  }

  let render_tab_content = (index: int) => {
    switch index {
    | 0 =>
      <Grid container=true spacing=#V3 alignItems=#Stretch>
        <Grid item=true xs={Grid.Xs._12}>
          <BoardList
            selector_name="board"
            items=config_lists.boards
            onChange={board => {
              setAppState({...appState, board: board})
            }}
            selected=appState.board
          />
        </Grid>
        <Grid item=true xs={Grid.Xs._12}>
          <StartStopButton
            itemName="board"
            doStart={() => start(~with_interface=false)}
            doStop=kill
            isStarted=is_started
            isReady={() => appState.board->Belt.Option.isSome}
          />
        </Grid>
      </Grid>

    | 1 =>
      <Grid container=true spacing=#V3 alignItems=#Stretch>
        <Grid item=true xs={Grid.Xs._6}>
          <BoardList
            selector_name="interface"
            items=config_lists.interfaces
            onChange={interface => {
              setAppState({...appState, interface: interface})
            }}
            selected=appState.interface
          />
        </Grid>
        <Grid item=true xs={Grid.Xs._6}>
          <BoardList
            selector_name="target"
            items=config_lists.targets
            onChange={target => {
              setAppState({...appState, target: target})
            }}
            selected=appState.target
          />
        </Grid>
        <Grid item=true xs={Grid.Xs._12}>
          <StartStopButton
            itemName="target with interface"
            doStart={() => start(~with_interface=true)}
            doStop=kill
            isStarted=is_started
            isReady={_ => {
              appState.target->Belt.Option.isSome && appState.interface->Belt.Option.isSome
            }}
          />
        </Grid>
      </Grid>

    | _ => <> </>
    }
  }

  <>
    <Grid container=true spacing=#V1 alignItems=#Stretch>
      <Grid item=true xs={Grid.Xs._3}>
        <Paper variant=#Outlined>
          <Tabs orientation=#Vertical onChange=handleTabPanelChange value={tab_panel_index->Any}>
            <Tab label={"A predefined Board"->React.string} />
            <Tab label={"A Target with an Interface"->React.string} />
          </Tabs>
        </Paper>
      </Grid>
      <Grid item=true xs={Grid.Xs._9}>
        <Card elevation={MaterialUi_Types.Number.int(3)}>
          <CardContent> {render_tab_content(tab_panel_index)} </CardContent>
        </Card>
      </Grid>
      <Grid item=true xs={Grid.Xs._12} />
    </Grid>
    <Paper elevation={MaterialUi_Types.Number.int(0)}>
      <TextField
        multiline=true
        rowsMax={TextField.RowsMax.int(18)}
        size=#Medium
        variant=#Outlined
        fullWidth=true
        placeholder="Openocd output..."
        disabled={openocd_output->Js.String2.length == 0}
        value={TextField.Value.string(openocd_output)}
      />
    </Paper>
  </>
}
