type t = {cmd: string}

@module("@tauri-apps/api/tauri") external myCustomCommand: string => unit = "invoke"

@react.component
let make = () => {
  open MaterialUi

  let (count, setCount) = React.useState(() => 0)

  React.useEffect1(() => {
    myCustomCommand("my_custom_command")

    None
  }, [count])

  <Container maxWidth={Container.MaxWidth.sm}>
    <Typography> {"Some example text"->React.string} </Typography>
    <Button color=#Primary variant=#Contained onClick={_ => setCount(count => count + 1)}>
      {j`Tauri backend invoked ${Belt.Int.toString(count)} times`->React.string}
    </Button>
  </Container>
}
