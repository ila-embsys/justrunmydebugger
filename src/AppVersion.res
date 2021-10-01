@module("./version.js") external version: string = "version"

@react.component
let make = () => {
  let style = ReactDOM.Style.make(
    ~position="fixed",
    ~bottom="0",
    ~right="0",
    ~color="#AAA",
    ~margin="1em",
    ~fontSize="0.8em",
    (),
  )

  <div style> {("version: " ++ version)->React.string} </div>
}
