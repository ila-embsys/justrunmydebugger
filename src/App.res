type config = {configs: array<BoardList.openocd_config_item>}
type config_type = {configType: string}

type selectedBoardName = option<string>

type payload = {message: string}
type event = {event_name: string, payload: payload}
type eventCallBack = event => unit

@module("@tauri-apps/api/tauri") external invoke: string => Promise.t<'data> = "invoke"
@module("@tauri-apps/api/tauri")
external invoke_start: (string, config) => Promise.t<'data> = "invoke"
@module("@tauri-apps/api/tauri")
external invoke_get_config_list: (string, config_type) => Promise.t<'data> = "invoke"
@module("@tauri-apps/api/event")
external listen: (~event_name: string, ~callback: eventCallBack) => Promise.t<'event> = "listen"

@react.component
let make = () => {
  open Promise
  open MaterialUi

  let default_boards: array<BoardList.openocd_config_item> = []
  let default_interfaces: array<BoardList.openocd_config_item> = []
  let default_targets: array<BoardList.openocd_config_item> = []

  let default_openocd_unlisten: option<unit => unit> = None

  let (boards, setBoards) = React.useState(() => default_boards)
  let (interfaces, setInterfaces) = React.useState(() => default_interfaces)
  let (targets, setTargets) = React.useState(() => default_targets)

  let (
    selected_board: option<BoardList.openocd_config_item>,
    setSelectedBoard,
  ) = React.useState(() => None)
  let (
    selected_interface: option<BoardList.openocd_config_item>,
    setSelectedInterface,
  ) = React.useState(() => None)
  let (
    selected_target: option<BoardList.openocd_config_item>,
    setSelectedTarget,
  ) = React.useState(() => None)

  let (openocd_output, set_openocd_output) = React.useState(() => "")
  let (is_started, set_is_started) = React.useState(() => false)
  let (openocd_unlisten, set_openocd_unlisten) = React.useState(() => default_openocd_unlisten)

  let (tab_panel_index, setTabPanelIndex) = React.useState(() => 0)

  React.useEffect1(() => {
    invoke_get_config_list("get_config_list", {configType: "BOARD"})
    ->then(b => {
      setBoards(_ => b)
      resolve()
    })
    ->ignore

    None
  }, [])

  React.useEffect1(() => {
    invoke_get_config_list("get_config_list", {configType: "INTERFACE"})
    ->then(b => {
      setInterfaces(_ => b)
      resolve()
    })
    ->ignore

    None
  }, [])

  React.useEffect1(() => {
    invoke_get_config_list("get_config_list", {configType: "TARGET"})
    ->then(b => {
      setTargets(_ => b)
      resolve()
    })
    ->ignore

    None
  }, [])

  let start = (boards: array<BoardList.openocd_config_item>) => {
    set_openocd_output(_ => "")

    invoke_start("start", {configs: boards})
    ->then(ret => {
      Js.Console.log(`Invoking OpenOCD return: ${ret}`)
      resolve()
    })
    ->ignore

    set_is_started(_ => true)
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
            items=boards
            onChange={board => setSelectedBoard(_ => board)}
            selected=selected_board
          />
        </Grid>
        <Grid item=true xs={Grid.Xs._12}>
          <StartButton
            item_name="board"
            config_items=[selected_board]
            doStart=start
            doStop=kill
            isStarted=is_started
            isReady={_ => {
              !(selected_board->Belt.Option.isNone)
            }}
          />
        </Grid>
      </Grid>

    | 1 =>
      <Grid container=true spacing=#V3 alignItems=#Stretch>
        <Grid item=true xs={Grid.Xs._6}>
          <BoardList
            selector_name="interface"
            items=interfaces
            onChange={interface => setSelectedInterface(_ => interface)}
            selected=selected_interface
          />
        </Grid>
        <Grid item=true xs={Grid.Xs._6}>
          <BoardList
            selector_name="target"
            items=targets
            onChange={target => setSelectedTarget(_ => target)}
            selected=selected_target
          />
        </Grid>
        <Grid item=true xs={Grid.Xs._12}>
          <StartButton
            item_name="target with interface"
            config_items=[selected_target, selected_interface]
            doStart=start
            doStop=kill
            isStarted=is_started
            isReady={_ => {
              !(selected_target->Belt.Option.isNone) && !(selected_interface->Belt.Option.isNone)
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
