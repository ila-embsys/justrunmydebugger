@react.component
let make = (
  ~id: string,
  ~label: string,
  ~value: string,
  ~onChange: string => unit,
  ~required: option<bool>=?,
) => {
  open Mui

  let callback = (event: ReactEvent.Form.t) => {
    let value: string = (event->ReactEvent.Form.target)["value"]
    onChange(value)
  }

  <TextField
    id
    label={label->React.string}
    value={value->TextField.Value.string}
    required={required->Belt.Option.getWithDefault(false)}
    onChange={callback}
    fullWidth=true
    margin=#none
    variant=#standard
  />
}
