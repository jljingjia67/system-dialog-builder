const { app, BrowserWindow, globalShortcut, ipcMain } = require('electron');
const path = require('path');

let win;

function createWindow() {
  win = new BrowserWindow({
    width: 320,
    height: 380,
    transparent: true,
    frame: false,
    alwaysOnTop: true,
    resizable: false,
    hasShadow: true,
    vibrancy: 'under-window',
    visualEffectState: 'active',
    backgroundColor: '#00000000',
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
    },
  });

  win.center();
  win.loadFile('dialog.html');

  // Start with click-through enabled, forwarding mouse events to renderer
  // so the renderer can detect when the cursor enters the dialog
  win.setIgnoreMouseEvents(true, { forward: true });

  win.on('closed', () => {
    win = null;
  });
}

// IPC handlers for toggling click-through from the renderer
ipcMain.on('set-ignore-mouse-events', (event, ignore, options) => {
  if (win) {
    win.setIgnoreMouseEvents(ignore, options || {});
  }
});

app.whenReady().then(() => {
  createWindow();

  globalShortcut.register('CommandOrControl+Q', () => {
    app.quit();
  });
});

app.on('window-all-closed', () => {
  app.quit();
});

app.on('will-quit', () => {
  globalShortcut.unregisterAll();
});
