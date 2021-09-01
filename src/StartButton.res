@react.component
let make = (
  ~board: option<BoardList.board>,
  ~doStart: BoardList.board => unit,
  ~doStop,
  ~isStarted: bool,
) => {
  let buttonMsg = (board: option<BoardList.board>) => {
    if isStarted {
      "Stop"
    } else {
      board->Belt.Option.mapWithDefault("Please select the board", b => `Run "${b.name}" board`)
    }
  }

  let on_click = {
    _ =>
      if isStarted {
        doStop()
      } else {
        switch board {
        | Some(board) => doStart(board)
        | None => Js.Console.log("Reject call non selected board")
        }
      }
  }

  let color = {
    if isStarted {
      #Secondary
    } else {
      #Primary
    }
  }

  <MaterialUi.Button
    color variant=#Contained onClick=on_click disabled={board->Belt.Option.isNone}>
    {board->buttonMsg}
  </MaterialUi.Button>
}
