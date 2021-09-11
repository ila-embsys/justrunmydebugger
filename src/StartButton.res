@react.component
let make = (
  ~item_name: string="config",
  ~config_item: option<BoardList.openocd_config_item>,
  ~doStart: array<BoardList.openocd_config_item> => unit,
  ~doStop,
  ~isStarted: bool,
  ~isReady: unit => bool=() => true,
) => {
  let buttonMsg = (board: option<BoardList.openocd_config_item>) => {
    if isStarted {
      "Stop"
    } else {
      board->Belt.Option.mapWithDefault(`Please select any ${item_name}`, b =>
        `Run the "${b.name}" ${item_name}`
      )
    }
  }

  let on_click = {
    _ =>
      if isStarted {
        doStop()
      } else {
        switch config_item {
        | Some(config_item) => doStart([config_item])
        | None => Js.Console.log(`Reject call non selected ${item_name}`)
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
      config_item->Belt.Option.isNone || !isReady()
    }
  }

  <MaterialUi.Button color variant=#Contained onClick=on_click disabled>
    {config_item->buttonMsg}
  </MaterialUi.Button>
}
