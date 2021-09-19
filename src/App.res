open Api
open AppHooks
open AppTypes

/// Component to render OpenOCD output
///
/// Accept openocd output string as a child. Render
/// multiline text filed with child string inside.
///
module OpenocdOutput = {
  open MaterialUi

  let placeholder: string = "Openocd output..."
  let max_row_count = TextField.RowsMax.int(18)

  @react.component
  let make = (~children: string) => {
    <TextField
      multiline=true
      rowsMax=max_row_count
      size=#Medium
      variant=#Outlined
      fullWidth=true
      placeholder
      disabled={children->Js.String2.length == 0}
      value={TextField.Value.string(children)}
    />
  }
}

/// Render children if `currentIndex` is equal to `tabIndex`
module TabContent = {
  @react.component
  let make = (~currentIndex: int, ~tabIndex: int, ~children: React.element) => {
    if currentIndex == tabIndex {
      children
    } else {
      <> </>
    }
  }
}

/// Main interface component
@react.component
let make = () => {
  open Promise
  open MaterialUi

  let (dumpedState, setDumpedState) = useDumpedState()
  let config_lists = useConfigLists()
  let (openocd_output, set_openocd_output) = useOpenocdOutput()
  let (tab_index, tabChangeHandler) = useMaterialUiTabIndex()

  let (is_started, set_is_started) = React.useState(() => false)

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
      [dumpedState.interface, dumpedState.target]
    } else {
      [dumpedState.board]
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

  // Tab with board selector
  let tab_board =
    <Grid container=true spacing=#V3 alignItems=#Stretch>
      <Grid item=true xs={Grid.Xs._12}>
        <BoardList
          selector_name="board"
          items=config_lists.boards
          onChange={board => {
            setDumpedState({...dumpedState, board: board})
          }}
          selected=dumpedState.board
        />
      </Grid>
      <Grid item=true xs={Grid.Xs._12}>
        <StartStopButton
          itemName="board"
          doStart={() => start(~with_interface=false)}
          doStop=kill
          isStarted=is_started
          isReady={() => dumpedState.board->Belt.Option.isSome}
        />
      </Grid>
    </Grid>

  // Tab with target and interface selectors
  let tab_target =
    <Grid container=true spacing=#V3 alignItems=#Stretch>
      <Grid item=true xs={Grid.Xs._6}>
        <BoardList
          selector_name="interface"
          items=config_lists.interfaces
          onChange={interface => {
            setDumpedState({...dumpedState, interface: interface})
          }}
          selected=dumpedState.interface
        />
      </Grid>
      <Grid item=true xs={Grid.Xs._6}>
        <BoardList
          selector_name="target"
          items=config_lists.targets
          onChange={target => {
            setDumpedState({...dumpedState, target: target})
          }}
          selected=dumpedState.target
        />
      </Grid>
      <Grid item=true xs={Grid.Xs._12}>
        <StartStopButton
          itemName="target with interface"
          doStart={() => start(~with_interface=true)}
          doStop=kill
          isStarted=is_started
          isReady={_ => {
            dumpedState.target->Belt.Option.isSome && dumpedState.interface->Belt.Option.isSome
          }}
        />
      </Grid>
    </Grid>

  /* Render: app interface */
  <>
    <Grid container=true spacing=#V1 alignItems=#Stretch>
      <Grid item=true xs={Grid.Xs._3}>
        <Paper variant=#Outlined>
          <Tabs orientation=#Vertical onChange=tabChangeHandler value={tab_index->Any}>
            <Tab label={"A predefined Board"->React.string} />
            <Tab label={"A Target with an Interface"->React.string} />
          </Tabs>
        </Paper>
      </Grid>
      <Grid item=true xs={Grid.Xs._9}>
        <Card elevation={MaterialUi_Types.Number.int(3)}>
          <CardContent>
            <TabContent currentIndex=tab_index tabIndex=0> {tab_board} </TabContent>
            <TabContent currentIndex=tab_index tabIndex=1> {tab_target} </TabContent>
          </CardContent>
        </Card>
      </Grid>
      <Grid item=true xs={Grid.Xs._12} />
    </Grid>
    <Paper elevation={MaterialUi_Types.Number.int(0)}>
      <OpenocdOutput> openocd_output </OpenocdOutput>
    </Paper>
  </>
}
