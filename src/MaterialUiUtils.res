/// Render children if `currentIndex` is equal to `tabIndex`
module TabContent = {
  @react.component
  let make = (~currentIndex: int, ~tabIndex: int, ~children: React.element) => {
    if currentIndex == tabIndex {
      children
    } else {
      <> </>
    }
  }
}

module Hooks = {
  /// Provide handler for a `MaterialUI.Tabs` component
  ///
  /// Convert `Any` index type from `MaterialUi` lib and return it as a number.
  ///
  let useMaterialUiTabIndex = () => {
    let (tabIndex, setTabIndex) = React.useReducer((_, v) => v, 0)

    let tabChangeHandler = (_, newValue: Mui.Any.t) => {
      setTabIndex(newValue->Mui.Any.unsafeToInt)
    }

    (tabIndex, tabChangeHandler)
  }
}
