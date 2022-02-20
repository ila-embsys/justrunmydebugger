/// Button with an optional progress
@react.component
let make = (~text: string, ~onClick: unit => unit, ~disabled: bool, ~loading: bool) => {
  let progress = (~loading: bool) => {
    if loading {
      <Mui.CircularProgress
        size={Mui.CircularProgress.Size.int(15)}
        style={ReactDOM.Style.make(~marginRight="10px", ())}
      />
    } else {
      <> </>
    }
  }

  <Mui.Button onClick={_ => onClick()} disabled>
    {progress(~loading)} {text->React.string}
  </Mui.Button>
}
