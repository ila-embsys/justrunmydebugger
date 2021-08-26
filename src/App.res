open Promise

type t = {cmd: string}

type board = {
  name: string,
  path: string,
}

@module("@tauri-apps/api/tauri") external invoke: string => Promise.t<'data> = "invoke"

@react.component
let make = () => {
  open MaterialUi
  open MaterialUi_Lab
  open ReactDOM

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
    <Typography> {"Some example text"->React.string} </Typography>
    <Button color=#Primary variant=#Contained onClick={_ => setCount(count => count + 1)}>
      {j`Tauri backend invoked ${Belt.Int.toString(count)} times`->React.string}
    </Button>
    <Autocomplete
      id="combo-box-list-boards"
      options={boards->Belt.Array.map(v => v->MaterialUi.Any)}
      getOptionLabel={b => b.name}
      style={Style.make(~width="300", ())}
      renderInput={params =>
        React.createElement(
          MaterialUi.TextField.make,
          Js.Obj.assign(params->Obj.magic, {"label": "Combo box", "variant": "outlined"}),
        )}
    />
  </Container>
}
