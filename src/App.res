type board = {
  name: string,
  path: string,
}

type config = {config: board}

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

  React.useEffect1(() => {
    invoke("my_custom_command")
    ->then(boards => {
      setBoards(boards)
      resolve()
    })
    ->ignore

    None
  }, [count])

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
            invoke1("start_for_config", {config: {name: "kek", path: "pek"}})
            ->then(ret => {
              Js.Console.log(ret)
              resolve()
            })
            ->ignore}>
          {"Run"}
        </Button>
      </Grid>
    </Grid>
  </Container>
}
