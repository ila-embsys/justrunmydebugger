// Original writer: Rickard Natt och Dag
// Source: https://dev.to/believer/rescript-using-usecontext-in-reasonreact-19p3

/// Generic type to provide description of a context internal data structure
/// and it's initial value
module type Config = {
  type context
  let defaultValue: context
}

/// Create a standard React context module parametrized with Config generic module type
///
/// This is a generic way to create contexts, there `context` type provides
/// stored in context data structure. Provider will be generated according to
/// recommendations in official ReScript docs.
/// See https://rescript-lang.org/docs/react/latest/context.
module Make = (Config: Config) => {
  let t = React.createContext(Config.defaultValue)

  module Provider = {
    let make = React.Context.provider(t)

    @obj
    external makeProps: (
      ~value: Config.context,
      ~children: React.element,
      ~key: string=?,
      unit,
    ) => {"value": Config.context, "children": React.element} = ""
  }

  /// Helper func to avoid using `React.useContext`
  let use = () => React.useContext(t)
}
