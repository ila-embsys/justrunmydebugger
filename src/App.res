type config = {config: BoardList.board}

type selectedBoardName = option<string>

type payload = {message: string}
type event = {event_name: string, payload: payload}
type eventCallBack = event => unit

@module("@tauri-apps/api/tauri") external invoke: string => Promise.t<'data> = "invoke"
@module("@tauri-apps/api/tauri") external invoke1: (string, config) => Promise.t<'data> = "invoke"
@module("@tauri-apps/api/event")
external listen: (~event_name: string, ~callback: eventCallBack) => Promise.t<'event> = "listen"

@react.component
let make = () => {
  open Promise
  open MaterialUi

  let default_boards: array<BoardList.board> = []
  let default_openocd_unlisten: option<unit => unit> = None

  let (count, setCount) = React.useState(() => 0)
  let (boards, setBoards) = React.useState(() => default_boards)
  let (selected_board: option<BoardList.board>, setSelectedBoard) = React.useState(() => None)
  let (openocd_output, set_openocd_output) = React.useState(() => "")
  let (openocd_listener_state, set_openocd_listener_state) = React.useState(() => false)
  let (openocd_unlisten, set_openocd_unlisten) = React.useState(() => default_openocd_unlisten)

  React.useEffect1(() => {
    invoke("get_board_list")
    ->then(b => {
      setBoards(_ => b)
      resolve()
    })
    ->ignore

    None
  }, [count])

  let start = (board: BoardList.board) => {
    set_openocd_listener_state(_ => true)

    invoke1("start_for_config", {config: board})
    ->then(ret => {
      Js.Console.log(`Invoking OpenOCD return: ${ret}`)
      resolve()
    })
    ->ignore
  }

  let kill = () => {
    invoke("kill")
    ->then(ret => {
      Js.Console.log(`Killing OpenOCD return: ${ret}`)
      resolve()
    })
    ->ignore

    set_openocd_listener_state(_ => false)
  }

  React.useEffect1(() => {
    if openocd_listener_state == true {
      set_openocd_output(_ => "")
      
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
    } else {
      switch openocd_unlisten {
      | Some(unlisten) => unlisten()
      | None => Js.Console.log(`Reset listener not found`)
      }
    }

    None
  }, [openocd_listener_state])

  <>
    <Container maxWidth={Container.MaxWidth.sm}>
      <Grid container=true spacing=#V6 alignItems=#Stretch>
        <Grid item=true xs={Grid.Xs._8}>
          <BoardList boards onChange={board => setSelectedBoard(_ => board)} />
        </Grid>
        <Grid item=true xs={Grid.Xs._4}>
          <Grid container=true spacing=#V3 alignItems=#Stretch>
            <Grid item=true xs={Grid.Xs._6}>
              <Button color=#Primary variant=#Outlined onClick={_ => setCount(count => count + 1)}>
                {"Update"}
              </Button>
            </Grid>
          </Grid>
        </Grid>
        <Grid item=true xs={Grid.Xs._12}>
          <StartButton
            board=selected_board doStart=start doStop=kill isStarted=openocd_listener_state
          />
        </Grid>
        <Grid item=true xs={Grid.Xs._12} />
      </Grid>
    </Container>
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
  </>
}
