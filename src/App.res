type board = {
  name: string,
  path: string,
}

type config = {config: board}

type selectedBoardName = option<string>

@module("@tauri-apps/api/tauri") external invoke: string => Promise.t<'data> = "invoke"
@module("@tauri-apps/api/tauri") external invoke1: (string, config) => Promise.t<'data> = "invoke"

@react.component
let make = () => {
  open Promise
  open MaterialUi
  open MaterialUi_Lab
  open Belt

  let a: array<board> = []

  let (count, setCount) = React.useState(() => 0)
  let (boards, setBoards) = React.useState(() => a)

  let (selected_board: selectedBoardName, setSelectedBoard) = React.useState(() => None)

  let (openOcdOutput, setOpenOcdOutput) = React.useState(() => "")

  React.useEffect1(() => {
    invoke("my_custom_command")
    ->then(b => {
      setBoards(_ => b)
      resolve()
    })
    ->ignore

    None
  }, [count])

  let handleChangeBoard = (e: ReactEvent.Form.t, _, _) => {
    let value = (e->ReactEvent.Form.target)["innerText"]
    setSelectedBoard(_ => {
      if value != "UNDEFINED" {
        Some(value)
      } else {
        None
      }
    })
  }

  let optionRender = (b: board, _) => {
    <Typography id={b.name}> {b.name} </Typography>
  }

  let is_board_available = (name: selectedBoardName) => {
    switch name {
    | None => false
    | Some(_) => true
    }
  }

  let run_buton_text = (name: selectedBoardName) => {
    switch name {
    | None => "Please select board"
    | Some(n) => `Run "${n}" board`
    }
  }

  <>
    <Container maxWidth={Container.MaxWidth.sm}>
      <Grid container=true spacing=#V6 alignItems=#Stretch>
        <Grid item=true xs={Grid.Xs._8}>
          <Autocomplete
            id="combo-box-list-boards"
            options={boards->Array.map(v => v->MaterialUi.Any)}
            getOptionLabel={b => b.name}
            style={ReactDOM.Style.make(~width="300", ())}
            renderInput={params =>
              React.createElement(
                MaterialUi.TextField.make,
                Js.Obj.assign(params->Obj.magic, {"label": "Select Boards", "variant": "outlined"}),
              )}
            onChange=handleChangeBoard
            renderOption=optionRender
          />
        </Grid>
        <Grid item=true xs={Grid.Xs._4}>
          <Grid container=true spacing=#V3 alignItems=#Stretch>
            <Grid item=true xs={Grid.Xs._6}>
              <Button color=#Primary variant=#Outlined onClick={_ => setCount(count => count + 1)}>
                {"Update"}
              </Button>
            </Grid>
            <Grid item=true xs={Grid.Xs._6}> {count->Int.toString->React.string} </Grid>
          </Grid>
        </Grid>
        <Grid item=true xs={Grid.Xs._12}>
          <Button
            color=#Primary
            variant=#Contained
            onClick={_ =>
              switch selected_board {
              | Some(n) => {
                  let board_config = Belt.Array.getBy(boards, b => b.name == n)

                  switch board_config {
                  | None =>
                    Js.Console.log("Selected board name not found in received OpenOCD config list")
                  | Some(c) =>
                    invoke1("start_for_config", {config: c})
                    ->then(ret => {
                      setOpenOcdOutput(ret)
                      resolve()
                    })
                    ->ignore
                  }
                }
              | None => Js.Console.log("Reject call non selected board")
              }}
            disabled={!is_board_available(selected_board)}>
            {run_buton_text(selected_board)}
          </Button>
        </Grid>
        <Grid item=true xs={Grid.Xs._12} />
      </Grid>
    </Container>
    <Typography
      component={MaterialUi.Typography.Component.string("pre")}
      style={ReactDOM.Style.make(~fontFamily="monospace", ())}>
      {openOcdOutput}
    </Typography>
  </>
}
