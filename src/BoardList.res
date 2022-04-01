open MuiLab

// Tricky convert `MaterialUi.Autocomplete.Value.t` to `Openocd.config_file_t`
external asOcdConfig: Autocomplete.Value.t => Openocd.config_file_t = "%identity"

@react.component
let make = (
  ~selector_name: string,
  ~items: array<Openocd.config_file_t>,
  ~onChange: option<Openocd.config_file_t> => unit,
  ~selected: option<Openocd.config_file_t>,
) => {
  open Belt
  open Mui

  let optionRender = (b: Openocd.config_file_t, _) => {
    <Typography> {b.name->React.string} </Typography>
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

    <Mui.TextField
      error
      key=selector_name
      required={true}
      label={`Select any ${selector_name}`->React.string}
      variant=#outlined
      inputProps={params["inputProps"]}
      \"InputProps"={params["InputProps"]}
      \"InputLabelProps"={params["InputLabelProps"]}
      disabled={params["disabled"]}
      fullWidth={params["fullWidth"]}
      id={params["id"]}
      size={params["size"]}
    />
  }

  let anchorOrigin = {
    Badge.AnchorOrigin.make(
      ~horizontal={#right},
      ~vertical={#top},
      (),
    )
  }

  
  let selected_name = Belt.Option.mapWithDefault(selected, "Nope", (c) => c.name)

  <>
    <Badge
      style={ReactDOM.Style.make(~display="block", ())}
      anchorOrigin
      max={Mui.Number.int(999)}
      badgeContent
      color=#primary>
      <Autocomplete
        value={selected->Mui.Any.make}
        key={`${selector_name}-${selected_name}`}
        options={items->Array.map(v => v->Mui.Any.make)}
        getOptionLabel={(item: Openocd.config_file_t) => item.name}
        renderInput
        onChange=handleChangeItem
        renderOption=optionRender
      />
    </Badge>
  </>
}
