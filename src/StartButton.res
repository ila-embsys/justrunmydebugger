@react.component
let make = (~board: option<BoardList.board>, ~onClick: BoardList.board => unit) => {
  let buttonMsg = (board: option<BoardList.board>) => {
    board->Belt.Option.mapWithDefault("Please select the board", b => `Run "${b.name}" board`)
  }

  <MaterialUi.Button
    color=#Primary
    variant=#Contained
    onClick={_ =>
      switch board {
      | Some(board) => onClick(board)
      | None => Js.Console.log("Reject call non selected board")
      }}
    disabled={board->Belt.Option.isNone}>
    {board->buttonMsg}
  </MaterialUi.Button>
}
