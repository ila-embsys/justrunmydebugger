@react.component
let make = (
  ~item_name: string="config",
  ~config_items: array<option<BoardList.openocd_config_item>>,
  ~doStart: array<BoardList.openocd_config_item> => unit,
  ~doStop,
  ~isStarted: bool,
  ~isReady: unit => bool=() => true,
) => {
  let buttonMsg = (board: option<BoardList.openocd_config_item>) => {
    if isStarted {
      "Stop"
    } else {
      switch board {
      | Some(b) => `Run the "${b.name}" ${item_name}`
      | _ => `Please select any ${item_name}`
      }
    }
  }

  let on_click = {
    _ =>
      if isStarted {
        doStop()
      } else {
        if (isReady())
        {
          let clear_configs = config_items->Belt.Array.map((item) => Belt.Option.getExn(item))
          doStart(clear_configs)
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

  let disabled = {
    if isStarted {
      false
    } else {
      !isReady()
    }
  }

  <MaterialUi.Button color variant=#Contained onClick=on_click disabled>
    {config_items[0]->buttonMsg}
  </MaterialUi.Button>
}
