# Just Run My Debugger!

This tool is a GUI for easy start and use OpenOCD. Built with Rust and Rescript
by very beginners of the both languages.

## Build

### Windows

On Windows 10 you should install WebView2 from here:
https://developer.microsoft.com/en-us/microsoft-edge/webview2. See more:
https://tauri.studio/en/docs/getting-started/setup-windows

Also update your Rust lo latest version.

### Linux

For linux follow the guide on Tauri page: [Setup for
Linux](https://tauri.studio/en/docs/getting-started/setup-linux#1-system-dependencies).

## Develop notes

### Debugging

Use command `yarn start` to build all and run application with hot reload.
If your IDE have rescript watcher use `yarn start:no-rewatch` to
start build without rescript watcher.

### rescript-logger

To configure rescript-logger set env variable for VSCode

```
RES_LOG=trace
```

Otherwise, rescript extension will run the compiler with no RES_LOG env
and generate code with default log level "warn".

Scripts in package.json already have preset envs
