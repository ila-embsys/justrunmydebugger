@react.component
let make = (
  ~itemName: string="config",
  ~doStart: unit => unit,
  ~doStop: unit => unit,
  ~isStarted: bool,
  ~isReady: unit => bool
) => {
  let buttonMsg = () => {
    let before_start_msg = `Please select any ${itemName}`

    if isStarted {
      "Stop"
    } else if isReady() {
      `Run the ${itemName}`
    } else {
      before_start_msg
    }
  }

  let on_click = _ => {
    if isStarted {
      doStop()
    } else if isReady() {
      doStart()
    }
  }

  let color = {
    if isStarted {
      #Secondary
    } else {
      #Primary
    }
  }

  let disabled = {
    if isStarted {
      false
    } else {
      !isReady()
    }
  }

  <MaterialUi.Button color variant=#Contained onClick=on_click disabled>
    {buttonMsg()}
  </MaterialUi.Button>
}
