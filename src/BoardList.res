open MaterialUi_Lab

type openocd_config_item = {
  name: string,
  path: string,
}

// Tricky convert `MaterialUi.Autocomplete.Value.t` to `openocd_config_item`
external asOcdConfig: Autocomplete.Value.t => openocd_config_item = "%identity"

@react.component
let make = (
  ~selector_name: string,
  ~items: array<openocd_config_item>,
  ~onChange: option<openocd_config_item> => unit,
) => {
  open Belt
  open MaterialUi

  let optionRender = (b: openocd_config_item, _) => {
    <Typography id={b.name}> {b.name} </Typography>
  }

  let handleChangeItem = (_: ReactEvent.Form.t, value: Autocomplete.Value.t, _) => {
    let item = asOcdConfig(value)
    let found = Belt.Array.getBy(items, b => b == item)
    onChange(found)
  }

  // let badgeContent = {
  //   let length = items->Belt.Array.length
  //   length->Belt.Int.toString->React.string
  // }

  let id = {
    `combo-box-list-${selector_name}`
  }

  // <Badge max=MaterialUi_Types.Number.int(999) badgeContent color=#Primary>
    <Autocomplete
      id
      options={items->Array.map(v => v->MaterialUi.Any)}
      getOptionLabel={item => item.name}
      // style={ReactDOM.Style.make(~width="300", ())}
      renderInput={params =>
        React.createElement(
          MaterialUi.TextField.make,
          Js.Obj.assign(
            params->Obj.magic,
            {"label": `Select any ${selector_name}`, "variant": "outlined"},
          ),
        )}
      onChange=handleChangeItem
      renderOption=optionRender
    />
  // </Badge>
}
