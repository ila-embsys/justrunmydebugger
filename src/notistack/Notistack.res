module SnackbarKey = {
  type t =
    | String(string)
    | Id(int)
}

module SnackbarMessage = {
  type t = React.element
}

module VariantType = {
  type t = [#default | #error | #success | #warning | #info]
}

module SnackbarContentCallback = {
  type t =
    | Jsx(React.element)
    | Func((~key: SnackbarKey.t, ~message: SnackbarMessage.t) => React.element)
}

module SnackbarAction = {
  type t =
    | Jsx(React.element)
    | Func((~key: SnackbarKey.t) => React.element)
}

module OptionsObject = {
  type t = {
    key: option<SnackbarKey.t>,
    persist: option<bool>,
    variant: option<VariantType.t>,
    preventDuplicate: option<bool>,
    content: option<SnackbarContentCallback.t>,
    action: option<SnackbarAction.t>,
  }

  let default: t = {
    variant: None,
    key: None,
    persist: None,
    preventDuplicate: None,
    content: None,
    action: None,
  }
}

module SnackbarMessageMsgJsx = {
  type t = React.element
}
module SnackbarMessageMsgString = {
  type t = string
}

module ProviderContext = {
  type t = {
    enqueueSnackbar: (
      ~message: SnackbarMessage.t,
      ~options: option<OptionsObject.t>,
    ) => SnackbarKey.t,
    closeSnackbar: (~key: option<SnackbarKey.t>) => unit,
  }
}

module Horizontal: {
  type t
  let left: t
  let right: t
} = {
  @unboxed
  type rec t = Any('a): t

  let left = Any("left")
  let right = Any("right")
}

module Vertical: {
  type t
  let bottom: t
  let top: t
} = {
  @unboxed
  type rec t = Any('a): t

  let bottom = Any("bottom")
  let top = Any("top")
}

module AnchorOrigin = {
  type t = {"horizontal": option<Horizontal.t>, "vertical": option<Vertical.t>}
  @obj
  external make: (~horizontal: Horizontal.t=?, ~vertical: Vertical.t=?, unit) => t = ""
}

module SnackbarProvider = {
  @obj
  external makeProps: (
    ~children: React.element=?,
    ~anchorOrigin: AnchorOrigin.t=?,
    ~dense: React.element=?,
    ~maxSnack: React.element=?,
    ~hideIconVariant: React.element=?,
    ~autoHideDuration: int=?,
    unit,
  ) => {
    "children": option<React.element>,
    "anchorOrigin": option<AnchorOrigin.t>,
    "dense": option<React.element>,
    "maxSnack": option<React.element>,
    "hideIconVariant": option<React.element>,
    "autoHideDuration": option<int>
  } = ""

  @module("notistack")
  external make: React.component<{
    "children": option<React.element>,
    "anchorOrigin": option<AnchorOrigin.t>,
    "dense": option<React.element>,
    "maxSnack": option<React.element>,
    "hideIconVariant": option<React.element>,
    "autoHideDuration": option<int>
  }> = "SnackbarProvider"
}

@module("notistack")
external useSnackbar: unit => ProviderContext.t = "useSnackbar"
