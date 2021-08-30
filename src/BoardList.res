open MaterialUi_Lab

type board = {
  name: string,
  path: string,
}

@react.component
let make = (~boards: array<board>, ~onChange: (option<board>) => unit) => {
  open Belt
  open MaterialUi

  let optionRender = (b: board, _) => {
    <Typography id={b.name}> {b.name} </Typography>
  }

  let handleChangeBoard = (e: ReactEvent.Form.t, _, _) => {
    let value = (e->ReactEvent.Form.target)["innerText"]
    let found = Js.Array2.find(boards, (b) => b.name == value)
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
