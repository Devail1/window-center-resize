/* eslint global-require: off, no-console: off */

import { BrowserWindow, app, ipcMain } from 'electron';
import sourceMapSupport from 'source-map-support';
import debug from 'electron-debug';
import { startAutoHotkeyProcess, stopAutoHotkeyProcess } from './autohotkey';
import { createWindow } from './window';
import {
  resetSettings,
  loadSettings,
  saveCenterSettings,
  saveResizeSettings,
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

app
  .whenReady()
  .then(() => {
    createWindow();
    createTrayMenu();
    startAutoHotkeyProcess();

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

ipcMain.handle('reset-settings', resetSettings);
ipcMain.handle('load-settings', loadSettings);
ipcMain.handle('get-settings', getSettings);
ipcMain.handle('save-center-settings', saveCenterSettings);
ipcMain.handle('save-resize-settings', saveResizeSettings);
