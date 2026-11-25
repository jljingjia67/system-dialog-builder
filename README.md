# System Dialog Builder

A customizable Apple-style system dialog, available three ways: a web builder, a native macOS app, and an Electron app.

## Download the Mac app (easiest)

1. Go to the [**latest release**](https://github.com/jljingjia67/system-dialog-builder/releases/latest) and download **System-Dialog-macOS.zip**.
2. Unzip it (double-click the zip).
3. **Right-click** `System Dialog.app` and choose **Open**, then click **Open** in the warning box.

> The right-click step is only needed the first time. macOS blocks unsigned apps on a normal double-click; right-click → Open tells it you trust this one. After that you can open it normally.
>
> If it says the app "is damaged" or won't open, run this once in Terminal (drag the app into the Terminal window after the command):
> ```bash
> xattr -cr "System Dialog.app"
> ```
>
> Apple Silicon Macs only (M1/M2/M3+).

The app floats over your desktop as a frameless, transparent, always-on-top dialog. Drag it by the top area; press Cancel, OK, Enter, or Escape to close.

## Use the web builder (no install)

Open **https://jljingjia67.github.io/system-dialog-builder/** to customize the dialog's icon, title, text, colors, fields, and buttons, then export or download the HTML.

## Build the Mac app from source

Needs the Xcode command line tools (`xcode-select --install`), which every Mac can install for free.

```bash
cd native-app
./build.sh
```

This produces `System Dialog.app` — double-click to run.

## Repo contents

- `index.html` / `prompt-ui.html` — the web builder (served by GitHub Pages)
- `native-app/` — Swift + WebKit source for the native Mac app (`main.swift`, `build.sh`)
- `electron-app/` — Electron version (needs Node.js)
