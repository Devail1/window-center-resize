/* eslint no-console: off */

import { BrowserWindow, app, ipcMain, screen } from 'electron';
import sourceMapSupport from 'source-map-support';
import debug from 'electron-debug';
import { startAutoHotkeyProcess, stopAutoHotkeyProcess } from './autohotkey';
import { createWindow } from './window';
import {
  resetSettings,
  saveCenterSettings,
  saveResizeSettings,
  saveSettings,
  closeWatcher,
  getSettings,
} from './settings';
import createTrayMenu from './tray';
import { startAppUpdater } from './updater';

if (process.env.NODE_ENV === 'production') {
  sourceMapSupport.install();
}

const isDebug =
  process.env.NODE_ENV === 'development' || process.env.DEBUG_PROD === 'true';

if (isDebug) {
  debug();
}

// Ensure we have a single instance of the app
const gotTheLock = app.requestSingleInstanceLock();

if (!gotTheLock) {
  app.quit();
} else {
  app.on('second-instance', () => {
    const windows = BrowserWindow.getAllWindows();
    if (windows.length) {
      const window = windows[0];
      if (window.isMinimized()) window.restore();
      window.focus();
    }
  });

  app
    .whenReady()
    .then(() => {
      createWindow();
      createTrayMenu();
      startAutoHotkeyProcess();

      // Register IPC handlers
      ipcMain.handle('get-settings', getSettings);
      ipcMain.handle('reset-settings', resetSettings);
      ipcMain.handle('save-center-settings', saveCenterSettings);
      ipcMain.handle('save-resize-settings', saveResizeSettings);
      ipcMain.handle('save-settings', saveSettings);
      ipcMain.handle('get-screen-size', () => {
        const primaryDisplay = screen.getPrimaryDisplay();
        return primaryDisplay.workAreaSize;
      });

      app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) createWindow();
      });

      app.on('will-quit', () => {
        closeWatcher();
        stopAutoHotkeyProcess();
      });

      startAppUpdater();
      return null;
    })
    .catch((error) => {
      console.error('Error in app.whenReady:', error);
    });
}
