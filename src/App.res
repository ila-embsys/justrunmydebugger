open Api
open AppHooks

let notificationAnchor = {
  open Notistack
  AnchorOrigin.make(~horizontal={Horizontal.right}, ~vertical={Vertical.bottom}, ())
}

/// Component to render OpenOCD output
///
/// Accept openocd output string as a child. Render
/// multiline text filed with child string inside.
///
module OpenocdOutput = {
  open Mui

  let placeholder: string = "Openocd output..."
  let max_row_count = TextField.RowsMax.int(18)

  @react.component
  let make = (~children: string) => {
    <TextField
      multiline=true
      rowsMax=max_row_count
      size=#medium
      variant=#outlined
      fullWidth=true
      placeholder
      disabled={children->Js.String2.length == 0}
      value={TextField.Value.string(children)}
    />
  }
}

/// App component
///
/// Arguments:
/// - saveSettings (AppTypes.Settings.t => unit): function to dump settings, see `useSettings` hook
///
@react.component
let make = (~saveSettings) => {
  open Promise
  open Mui
  open MuiUtils
  open SettingsContext

  let (is_configs_found, config_lists) = useConfigLists()
  let openocd_event = AppHooks.useOpenocdEvent()
  let (openocd_output, set_openocd_output) = useOpenocdOutput()
  let (tab_index, tabChangeHandler) = MuiUtils.Hooks.useMaterialUiTabIndex()
  let (is_started, set_is_started) = React.useState(() => false)
  let (settings, updateSettings) = SettingsContext.Context.use()

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
      [settings.openocd.interface, settings.openocd.target]
    } else {
      [settings.openocd.board]
    }

    if configs->every(c => c->isSome) {
      set_openocd_output("")

      invoke_start({
        configs: configs->unwrap_opt_array,
      })
      ->then(ret => {
        %log.info(
          "Invoking OpenOCD return:"
          ("ret", ret)
        )
        resolve()
      })
      ->catch(err => {
        %log.error(
          "Invoking OpenOCD raise an exception:"
          ("Api.promise_error_msg(err)", Api.promise_error_msg(err))
        )
        resolve()
      })
      ->ignore
    }
  }

  /* Stop OpenOCD */
  let kill = () => {
    invoke_kill()
    ->then(ret => {
      %log.info(
        "Killing OpenOCD return"
        ("ret", ret)
      )
      resolve()
    })
    ->catch(err => {
      %log.error(
        "Killing OpenOCD raise an exception"
        ("Api.promise_error_msg(err)", Api.promise_error_msg(err))
      )
      resolve()
    })
    ->ignore
  }

  // Save settings every time it's updated
  React.useEffect1(() => {
    saveSettings(settings)
    None
  }, [settings])

  // Handle OpenOCD start/stop events for StartStop button
  React.useEffect1(() => {
    switch openocd_event {
    | Some(openocd_event) =>
      switch openocd_event {
      | Start => set_is_started(_ => true)
      | Stop => set_is_started(_ => false)
      }
    | None => ()
    }

    None
  }, [openocd_event])

  // Tab with board selector
  let tab_board =
    <Grid container=true spacing=#3 alignItems=#stretch>
      <Grid item=true xs={Grid.Xs.\"12"}>
        <BoardList
          selector_name="board"
          items=config_lists.boards
          onChange={board => updateSettings(Update.Board(board))}
          selected=settings.openocd.board
        />
      </Grid>
      <Grid item=true xs={Grid.Xs.\"12"}>
        <StartStopButton
          itemName="board"
          doStart={() => start(~with_interface=false)}
          doStop=kill
          isStarted=is_started
          isReady={() => settings.openocd.board->Belt.Option.isSome}
        />
      </Grid>
    </Grid>

  // Tab with target and interface selectors
  let tab_target =
    <Grid container=true spacing=#3 alignItems=#stretch>
      <Grid item=true xs={Grid.Xs.\"6"}>
        <BoardList
          selector_name="interface"
          items=config_lists.interfaces
          onChange={interface => updateSettings(Update.Interface(interface))}
          selected=settings.openocd.interface
        />
      </Grid>
      <Grid item=true xs={Grid.Xs.\"6"}>
        <BoardList
          selector_name="target"
          items=config_lists.targets
          onChange={target => updateSettings(Update.Target(target))}
          selected=settings.openocd.target
        />
      </Grid>
      <Grid item=true xs={Grid.Xs.\"12"}>
        <StartStopButton
          itemName="target with interface"
          doStart={() => start(~with_interface=true)}
          doStop=kill
          isStarted=is_started
          isReady={_ => {
            settings.openocd.target->Belt.Option.isSome &&
              settings.openocd.interface->Belt.Option.isSome
          }}
        />
      </Grid>
    </Grid>

  /* Render: app interface */
  <Notistack.SnackbarProvider anchorOrigin=notificationAnchor autoHideDuration={2000}>
    <MuiExt.Loading display={!is_configs_found} />
    <Grow \"in"=is_configs_found>
      <div>
        <Grid container=true spacing=#1 alignItems=#stretch>
          <Grid item=true xs={Grid.Xs.\"3"}>
            <Paper variant=#outlined>
              <Tabs orientation=#vertical onChange=tabChangeHandler value={tab_index->Any.fromInt}>
                <Tab label={"A predefined Board"->React.string} />
                <Tab label={"A Target with an Interface"->React.string} />
              </Tabs>
            </Paper>
          </Grid>
          <Grid item=true xs={Grid.Xs.\"9"}>
            <Card elevation={Mui.Number.int(3)}>
              <CardContent>
                <TabContent currentIndex=tab_index tabIndex=0> {tab_board} </TabContent>
                <TabContent currentIndex=tab_index tabIndex=1> {tab_target} </TabContent>
              </CardContent>
            </Card>
          </Grid>
          <Grid item=true xs={Grid.Xs.\"12"} />
        </Grid>
        <Paper elevation={Mui.Number.int(0)}>
          <OpenocdOutput> openocd_output </OpenocdOutput>
        </Paper>
        <SnackbarOpenocdMessages />
      </div>
    </Grow>
    <Fade \"in"=is_configs_found> <div> <AppVersion /> <GitpodButton /> </div> </Fade>
  </Notistack.SnackbarProvider>
}
