/// Root component
///
/// Render App only after settings was loaded from backend.
///
@react.component
let make = () => {
  let (settings, saveSettings) = AppHooks.useSettings()

  switch settings {
  | Some(settings) =>
    <SettingsContext.Provider initial=settings> <App saveSettings /> </SettingsContext.Provider>
  | None => <MuiExt.Loading display=true />
  }
}
