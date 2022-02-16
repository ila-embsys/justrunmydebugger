@react.component
let make = (~id: string, ~label: string, ~onChange: string => unit, ~required: option<bool>=?) => {
  open Mui

  let callback = (event: ReactEvent.Form.t) => {
    let value: string = (event->ReactEvent.Form.target)["value"]
    onChange(value)
  }

  <TextField
    id
    label={label->React.string}
    required={required->Belt.Option.getWithDefault(false)}
    value={""->TextField.Value.string}
    onChange={callback}
    fullWidth=true
    margin=#none
    variant=#standard
  />
}
