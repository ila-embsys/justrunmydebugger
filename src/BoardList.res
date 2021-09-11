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
  ~selected: option<openocd_config_item>,
) => {
  open Belt
  open MaterialUi

  let optionRender = (b: openocd_config_item, _) => {
    <Typography> {b.name} </Typography>
  }

  let handleChangeItem = (_: ReactEvent.Form.t, value: Autocomplete.Value.t, _) => {
    let value = value->Js.Nullable.return->Js.Nullable.toOption

    switch value {
    | Some(value) => {
        let item = asOcdConfig(value)
        let found = Belt.Array.getBy(items, b => b == item)
        onChange(found)
      }
    | None => onChange(None)
    }
  }

  let badgeContent = {
    let length = items->Belt.Array.length
    length->Belt.Int.toString->React.string
  }

  let renderInput = (params: Js.t<{..} as 'a>) => {
    let error = {
      switch selected {
      | Some(_) => false
      | None => true
      }
    }
    Js.Console.log(params)

    <MaterialUi.TextField
      error
      key=selector_name
      required={true}
      label={`Select any ${selector_name}`->React.string}
      variant=#Outlined
      inputProps={params["inputProps"]}
      _InputProps={params["InputProps"]}
      _InputLabelProps={params["InputLabelProps"]}
      disabled={params["disabled"]}
      fullWidth={params["fullWidth"]}
      id={params["id"]}
      size={params["size"]}
    />
  }

  let anchorOrigin = {
    Badge.AnchorOrigin.make(
      ~horizontal={Badge.Horizontal.right},
      ~vertical={Badge.Vertical.top},
      (),
    )
  }

  <>
    <Badge
      style={ReactDOM.Style.make(~display="block", ())}
      anchorOrigin
      max={MaterialUi_Types.Number.int(999)}
      badgeContent
      color=#Primary>
      <Autocomplete
        value={Any(selected)}
        key=selector_name
        options={items->Array.map(v => v->Any)}
        getOptionLabel={item => item.name}
        renderInput
        onChange=handleChangeItem
        renderOption=optionRender
      />
    </Badge>
  </>
}
