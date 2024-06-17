/* eslint global-require: off, no-console: off, promise/always-return: off */

/**
 * This module executes inside of electron's main process. You can start
 * electron renderer process from here and communicate with the other processes
 * through IPC.
 *
 * When running `npm run build` or `npm run build:main`, this file is compiled to
 * `./src/main.js` using webpack. This gives us some performance wins.
 */
import { BrowserWindow, app, dialog, ipcMain } from 'electron';
import sourceMapSupport from 'source-map-support';
import debug from 'electron-debug';
import { autoUpdater } from 'electron-updater';
import log from 'electron-log';
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

autoUpdater.logger = log;
log.transports.file.level = 'info';
log.info('App starting...');

autoUpdater.on('checking-for-update', () => {
  log.info('Checking for update...');
});

autoUpdater.on('update-available', (info) => {
  log.info('Update available.', info);
});

autoUpdater.on('update-not-available', (info) => {
  log.info('Update not available.', info);
});

autoUpdater.on('error', (err) => {
  log.info('Error in auto-updater. ', err);
});

autoUpdater.on('download-progress', (progressObj) => {
  let logMessage = `Download speed: ${progressObj.bytesPerSecond}`;
  logMessage = `${logMessage} - Downloaded ${progressObj.percent}%`;
  logMessage = `${logMessage} (${progressObj.transferred}/${progressObj.total})`;
  log.info(logMessage);
});

autoUpdater.on('update-downloaded', (info) => {
  log.info('Update downloaded', info);
  // Show a dialog to the user to confirm restart
  dialog
    .showMessageBox({
      type: 'info',
      title: 'Update Available',
      message:
        'A new version is available. Do you want to restart the application to apply the updates now?',
      buttons: ['Restart', 'Later'],
    })
    .then((result) => {
      const buttonIndex = result.response;
      if (buttonIndex === 0) {
        autoUpdater.quitAndInstall();
      }
    })
    .catch((error) => {
      console.error('Error in auto-updater. ', error);
    });
  autoUpdater.quitAndInstall();
});

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

    // Check for updates and notify
    autoUpdater.checkForUpdatesAndNotify();
  })
  .catch((error) => {
    console.error('Error in app.whenReady:', error);
  });

ipcMain.handle('reset-settings', resetSettings);
ipcMain.handle('load-settings', loadSettings);
ipcMain.handle('get-settings', getSettings);
ipcMain.handle('save-center-settings', saveCenterSettings);
ipcMain.handle('save-resize-settings', saveResizeSettings);
