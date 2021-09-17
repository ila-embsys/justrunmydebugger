open Api
open AppHooks
open AppTypes

@react.component
let make = () => {
  open Promise
  open MaterialUi

  let (appState, setAppState) = useAppState()

  let (config_lists: config_lists_t, setConfigLists) = React.useState(() => {
    boards: [],
    interfaces: [],
    targets: [],
  })

  let (is_started, set_is_started) = React.useState(() => false)

  let (tab_panel_index, setTabPanelIndex) = React.useState(() => 0)

  let (openocd_output, set_openocd_output) = useOpenocdOutput()

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

  /* Start OpenOCD process on backend with selected configs */
  let start = (~with_interface: bool) => {
    open Belt_Array
    open Belt_Option

    /* Convert array<option<'a>> to array<'a> with None elements removed */
    let unwrap_opt_array = (array: array<option<'a>>) => {
      array->reduce([], (arr, el) => {
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
        configs: configs->unwrap_opt_array,
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

  /* Tab onChange handler, set current tab index */
  let handleTabPanelChange = (_, newValue: MaterialUi_Types.any) => {
    setTabPanelIndex(newValue->MaterialUi_Types.anyUnpack)
  }

  /* Render tab content depending on index */
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

  /* Render: app interface */
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
