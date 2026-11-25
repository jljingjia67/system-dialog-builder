# System Dialog Builder

A customizable Apple-style system dialog, available three ways: a web builder, a native macOS app, and an Electron app.

## Run the Mac app with no approval prompt (recommended)

Because the app is unsigned, a *downloaded* copy makes macOS show the "unidentified developer" approval prompt. The way around that — with no Apple Developer account and nothing bypassed — is to **build it on your own Mac from source**. A locally compiled app is never flagged by macOS, so it just opens.

Needs the free Xcode command line tools once (`xcode-select --install`), then:

```bash
git clone https://github.com/jljingjia67/system-dialog-builder.git
cd system-dialog-builder/native-app
./build.sh
```

`build.sh` compiles the app and launches it immediately — no approval prompt. The built `System Dialog.app` sits in the `native-app` folder; drag it to your Applications folder to keep it.

The app opens as a window with the full builder UI — the same one as the website — where you customize the dialog's icon, title, text, colors, input fields, buttons, and theme, with a live preview.

## Update to the latest version

If you installed by building from source (above), update anytime from the repo folder:

```bash
./update.sh
```

It pulls the newest code and rebuilds the app, then relaunches it.

## Download the pre-built app (shows a one-time prompt)

Prefer not to build it? Grab **System-Dialog-macOS.zip** from the [**latest release**](https://github.com/jljingjia67/system-dialog-builder/releases/latest), unzip it, then **right-click** `System Dialog.app` → **Open** → **Open**. That one-time step is macOS asking you to confirm you trust a downloaded unsigned app; after it, the app opens normally. (Apple Silicon Macs only for the pre-built download.)

## Use the web builder (no install)

Open **https://jljingjia67.github.io/system-dialog-builder/** to customize the dialog's icon, title, text, colors, fields, and buttons, then export or download the HTML.

## Repo contents

- `index.html` / `prompt-ui.html` — the web builder (served by GitHub Pages)
- `native-app/` — Swift + WebKit source for the native Mac app (`main.swift`, `build.sh`)
- `electron-app/` — Electron version (needs Node.js)
