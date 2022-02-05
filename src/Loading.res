let backdrop_style = ReactDOM.Style.make(~zIndex="9999", ())

@react.component
let make = (~display: bool) => {
  open Mui
  <Backdrop \"open"={display} style=backdrop_style> <CircularProgress color=#inherit /> </Backdrop>
}
