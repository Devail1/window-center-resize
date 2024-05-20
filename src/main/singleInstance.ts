/* eslint import/prefer-default-export: off */
import { app, BrowserWindow } from 'electron';

export function handleSingleInstance(mainWindow: BrowserWindow) {
  const gotTheLock = app.requestSingleInstanceLock();

  if (!gotTheLock) {
    app.quit();
  } else {
    app.on('second-instance', () => {
      if (mainWindow) {
        if (!mainWindow.isVisible()) {
          mainWindow.restore();
        }
        mainWindow.focus();
      }
      app.relaunch();
      app.quit();
    });
  }
}
