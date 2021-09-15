type configs = {configs: array<Openocd.config_t>}
type config_type = {configType: string}
type payload = {message: string}
type event = {event_name: string, payload: payload}
type eventCallBack = event => unit
type dump_state_t = {dumped: Openocd.app_config_t}

type config_set_t = {
  board: option<Openocd.config_t>,
  interface: option<Openocd.config_t>,
  target: option<Openocd.config_t>,
}

type config_lists_t = {
  boards: array<Openocd.config_t>,
  interfaces: array<Openocd.config_t>,
  targets: array<Openocd.config_t>,
}

@module("@tauri-apps/api/tauri") external invoke: string => Promise.t<'data> = "invoke"
@module("@tauri-apps/api/tauri")
external invoke_start: (string, configs) => Promise.t<'data> = "invoke"
@module("@tauri-apps/api/tauri")
external invoke_get_config_list: (string, config_type) => Promise.t<'data> = "invoke"
@module("@tauri-apps/api/event")
external listen: (~event_name: string, ~callback: eventCallBack) => Promise.t<'event> = "listen"
@module("@tauri-apps/api/tauri")
external invoke_dump_state: (string, dump_state_t) => Promise.t<'data> = "invoke"

@react.component
let make = () => {
  open Promise
  open MaterialUi

  let default_openocd_unlisten: option<unit => unit> = None

  let (config_set: config_set_t, setConfigSet) = React.useState(() => {
    board: None,
    interface: None,
    target: None,
  })

  let (config_lists: config_lists_t, setConfigLists) = React.useState(() => {
    boards: [],
    interfaces: [],
    targets: [],
  })

  let (openocd_output, set_openocd_output) = React.useState(() => "")
  let (is_started, set_is_started) = React.useState(() => false)
  let (openocd_unlisten, set_openocd_unlisten) = React.useState(() => default_openocd_unlisten)

  let (tab_panel_index, setTabPanelIndex) = React.useState(() => 0)

  let dump_state = (config_set: config_set_t) => {
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

    invoke_dump_state("dump_state", {dumped: conf_to_save})
    ->then(_ => {
      Js.Console.log("Dump selectors state")
      Js.Console.log(conf_to_save)
      resolve()
    })
    ->ignore
  }

  React.useEffect1(() => {
    invoke_get_config_list("get_config_list", {configType: "BOARD"})
    ->then(boards => {
      setConfigLists(lists => {...lists, boards: boards})
      resolve()
    })
    ->ignore

    invoke_get_config_list("get_config_list", {configType: "INTERFACE"})
    ->then(interfaces => {
      setConfigLists(lists => {...lists, interfaces: interfaces})
      resolve()
    })
    ->ignore

    invoke_get_config_list("get_config_list", {configType: "TARGET"})
    ->then(targets => {
      setConfigLists(lists => {...lists, targets: targets})
      resolve()
    })
    ->ignore

    invoke("load_state")
    ->then((conf: Openocd.app_config_t) => {
      Js.Console.log("Load selectors state")
      Js.Console.log(conf)

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
      [config_set.interface, config_set.target]
    } else {
      [config_set.board]
    }

    if configs->every(c => c->isSome) {
      set_openocd_output(_ => "")

      invoke_start(
        "start",
        {
          configs: configs->unwrap_configs,
        },
      )
      ->then(ret => {
        Js.Console.log(`Invoking OpenOCD return: ${ret}`)
        resolve()
      })
      ->ignore

      set_is_started(_ => true)
    }
  }

  let kill = () => {
    invoke("kill")
    ->then(ret => {
      Js.Console.log(`Killing OpenOCD return: ${ret}`)
      resolve()
    })
    ->ignore

    set_is_started(_ => false)
  }

  React.useEffect1(() => {
    if openocd_unlisten->Belt.Option.isNone {
      Js.Console.log(`Listener state: ${Js.String.make(is_started)}`)

      listen(~event_name="openocd-output", ~callback=e => {
        Js.Console.log(`Call listener`)
        let payload = e.payload
        let message = payload.message

        Js.Console.log(`payload: ${message}`)

        let rec text_cuter = (text: string, length: int) => {
          if text->Js.String.length > length {
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

        set_openocd_output(output => {
          (output ++ message)->text_cuter(5000)
        })
      })
      ->then(unlisten => {
        set_openocd_unlisten(_ => Some(unlisten))
        Js.Console.log(`Set listener`)

        resolve()
      })
      ->ignore
    }
    None
  }, [])

  let handleTabPanelChange = (_, newValue: MaterialUi_Types.any) => {
    setTabPanelIndex(newValue->MaterialUi_Types.anyUnpack)
  }

  let tab_content = (index: int) => {
    switch index {
    | 0 =>
      <Grid container=true spacing=#V3 alignItems=#Stretch>
        <Grid item=true xs={Grid.Xs._12}>
          <BoardList
            selector_name="board"
            items=config_lists.boards
            onChange={board => {
              setConfigSet(config => {...config, board: board})
              dump_state({...config_set, board: board})
            }}
            selected=config_set.board
          />
        </Grid>
        <Grid item=true xs={Grid.Xs._12}>
          <StartStopButton
            itemName="board"
            doStart={() => start(~with_interface=false)}
            doStop=kill
            isStarted=is_started
            isReady={() => config_set.board->Belt.Option.isSome}
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
              setConfigSet(config => {...config, interface: interface})
              dump_state({...config_set, interface: interface})
            }}
            selected=config_set.interface
          />
        </Grid>
        <Grid item=true xs={Grid.Xs._6}>
          <BoardList
            selector_name="target"
            items=config_lists.targets
            onChange={target => {
              setConfigSet(config => {...config, target: target})
              dump_state({...config_set, target: target})
            }}
            selected=config_set.target
          />
        </Grid>
        <Grid item=true xs={Grid.Xs._12}>
          <StartStopButton
            itemName="target with interface"
            doStart={() => start(~with_interface=true)}
            doStop=kill
            isStarted=is_started
            isReady={_ => {
              config_set.target->Belt.Option.isSome &&
              config_set.interface->Belt.Option.isSome
            }}
          />
        </Grid>
      </Grid>

    | _ => <> </>
    }
  }

  let tab_content_resolve = tab_content(tab_panel_index)

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
          <CardContent> tab_content_resolve </CardContent>
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
