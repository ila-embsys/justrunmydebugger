type config = {config: BoardList.board}

type selectedBoardName = option<string>

@module("@tauri-apps/api/tauri") external invoke: string => Promise.t<'data> = "invoke"
@module("@tauri-apps/api/tauri") external invoke1: (string, config) => Promise.t<'data> = "invoke"

@react.component
let make = () => {
  open Promise
  open MaterialUi

  let a: array<BoardList.board> = []

  let (count, setCount) = React.useState(() => 0)
  let (boards, setBoards) = React.useState(() => a)
  let (selected_board: option<BoardList.board>, setSelectedBoard) = React.useState(() => None)
  let (openOcdOutput, setOpenOcdOutput) = React.useState(() => "")

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
    invoke1("start_for_config", {config: board})
    ->then(ret => {
      setOpenOcdOutput(ret)
      resolve()
    })
    ->ignore
  }

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
        <Grid item=true xs={Grid.Xs._12}> <StartButton board=selected_board onClick=start /> </Grid>
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
      disabled={openOcdOutput->Js.String2.length == 0}
      value={TextField.Value.string(openOcdOutput)}
    />
  </>
}
