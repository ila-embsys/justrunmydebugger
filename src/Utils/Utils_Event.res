/// Extract "value" from event
let value = (event: ReactEvent.Form.t): string => {
  (event->ReactEvent.Form.target)["value"]
}
