%%raw(`import "@fontsource/roboto/400.css";`)

switch ReactDOM.querySelector("#root") {
| Some(root) => ReactDOM.render(<Root />, root)
| None => ()
}
