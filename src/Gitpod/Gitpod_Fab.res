module Icon = {
  type t =
    | Normal
    | Loading
    | Success
    | Fail

  let render = (icon: t) => {
    switch icon {
    | Normal => <MuiExt.Icon.Cloud.Normal />
    | Loading => <Mui.CircularProgress size={Mui.CircularProgress.Size.int(30)} />
    | Success => <MuiExt.Icon.Cloud.Success />
    | Fail => <MuiExt.Icon.Cloud.Fail />
    }
  }
}

@react.component
let make = (~onClick: unit => unit, ~icon: Icon.t) => {
  let fab_style = ReactDOM.Style.make(
    ~position="fixed",
    ~bottom="40px",
    ~right="20px",
    ~top="auto",
    ~left="auto",
    ~margin="0",
    (),
  )

  <Mui.Fab color=#default style=fab_style onClick={_ => onClick()}> {icon->Icon.render} </Mui.Fab>
}
