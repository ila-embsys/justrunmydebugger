@react.component
let make = (
  ~itemName: string="config",
  ~doStart: unit => unit,
  ~doStop: unit => unit,
  ~isStarted: bool,
  ~isReady: unit => bool,
) => {
  let (is_loading, set_is_loading) = React.useState(() => false)
  let (loading_timeout_id, set_loading_timeout_id) = React.useState(() => None)

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

  let set_mark_button_as_loading = () => {
    set_is_loading(_ => true)

    let on_timeout = () => {
      set_is_loading(_ => false)
    }

    let timeout_id = Js.Global.setTimeout(on_timeout, 1000)
    set_loading_timeout_id(_ => Some(timeout_id))
  }

  let clear_mark_button_as_loading = () => {
    set_is_loading(_ => false)

    switch loading_timeout_id {
    | Some(id) => Js.Global.clearTimeout(id)
    | None => ()
    }

    set_loading_timeout_id(_ => None)
  }

  let on_click = _ => {
    if isStarted {
      doStop()
    } else if isReady() {
      set_mark_button_as_loading()
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
    if is_loading == true {
      true
    } else if isStarted {
      false
    } else {
      !isReady()
    }
  }

  React.useEffect1(() => {
    if isStarted {
      clear_mark_button_as_loading()
    }
    None
  }, [isStarted])

  let make = {
    if is_loading {
      <MaterialUi.CircularProgress size={MaterialUi.CircularProgress.Size.int(25)} />
    } else {
      buttonMsg()->React.string
    }
  }

  <MaterialUi.Button color variant=#Contained onClick=on_click disabled> {make} </MaterialUi.Button>
}
