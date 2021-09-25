type snackbarKey =
  | Name(string)
  | Number(int)

type optionsObject = {
  key: option<snackbarKey>,
  persist: option<bool>,
}

type snackbarMessageMsgJsx = React.element
type snackbarMessageMsgString = string

type providerContextMsgJsx = {
  enqueueSnackbar: (
    ~message: snackbarMessageMsgJsx,
    ~options: option<optionsObject>,
  ) => snackbarKey,
  closeSnackbar: (~key: option<snackbarKey>) => unit,
}

type providerContextMsgString = {
  enqueueSnackbar: (
    ~message: snackbarMessageMsgString,
    ~options: option<optionsObject>,
  ) => snackbarKey,
  closeSnackbar: (~key: option<snackbarKey>) => unit,
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
    unit,
  ) => {
    "children": option<React.element>,
    "anchorOrigin": option<AnchorOrigin.t>,
    "dense": option<React.element>,
    "maxSnack": option<React.element>,
    "hideIconVariant": option<React.element>,
  } = ""

  @module("notistack")
  external make: React.component<{
    "children": option<React.element>,
    "anchorOrigin": option<AnchorOrigin.t>,
    "dense": option<React.element>,
    "maxSnack": option<React.element>,
    "hideIconVariant": option<React.element>,
  }> = "SnackbarProvider"
}

@module("notistack")
external useSnackbarMsgJsx: unit => providerContextMsgJsx = "useSnackbar"

@module("notistack")
external useSnackbarMsgString: unit => providerContextMsgString = "useSnackbar"
