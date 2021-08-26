open Promise

type t = {cmd: string}

type board = {
  name: string,
  path: string
}

@module("@tauri-apps/api/tauri") external invoke: string => Promise.t<'data> = "invoke"

@react.component
let make = () => {
  open MaterialUi

  let a : array<board> = []

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

  let board_names = Belt.Array.map(boards, (board) => 
    <Typography> {j`${board.name}`->React.string} </Typography>)

  <Container maxWidth={Container.MaxWidth.sm}>
    <Typography> {"Some example text"->React.string} </Typography>
    <Button color=#Primary variant=#Contained onClick={_ => setCount(count => count + 1)}>
      {j`Tauri backend invoked ${Belt.Int.toString(count)} times`->React.string}
    </Button>
    {React.array(board_names)}
  </Container>

}
