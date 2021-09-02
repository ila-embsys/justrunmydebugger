open MaterialUi_Lab

type board = {
  name: string,
  path: string,
}

// Tricky convert `MaterialUi.Autocomplete.Value.t` to `board`
external asBoard: Autocomplete.Value.t => board = "%identity"

@react.component
let make = (~boards: array<board>, ~onChange: option<board> => unit) => {
  open Belt
  open MaterialUi

  let optionRender = (b: board, _) => {
    <Typography id={b.name}> {b.name} </Typography>
  }

  let handleChangeBoard = (_: ReactEvent.Form.t, value: Autocomplete.Value.t, _) => {
    let board = asBoard(value)
    let found = Belt.Array.getBy(boards, b => b == board)
    onChange(found)
  }

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
}
