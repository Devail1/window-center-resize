/* eslint global-require: off, no-console: off, promise/always-return: off */

/**
 * This module executes inside of electron's main process. You can start
 * electron renderer process from here and communicate with the other processes
 * through IPC.
 *
 * When running `npm run build` or `npm run build:main`, this file is compiled to
 * `./src/main.js` using webpack. This gives us some performance wins.
 */
import { BrowserWindow, app, ipcMain } from 'electron';
import sourceMapSupport from 'source-map-support';
import debug from 'electron-debug';
import { startAutoHotkeyProcess, stopAutoHotkeyProcess } from './autohotkey';
import { createWindow, getMainWindow } from './window';
import {
  resetSettings,
  loadSettings,
  saveCenterSettings,
  saveResizeSettings,
  closeWatcher,
  getSettings,
} from './settings';
import createTrayMenu from './tray';
import { handleSingleInstance } from './singleInstance';

ipcMain.on('ipc-example', async (event, arg) => {
  const msgTemplate = (pingPong: string) => `IPC test: ${pingPong}`;
  console.log(msgTemplate(arg));
  event.reply('ipc-example', msgTemplate('hello'));
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
  })
  .catch((error) => {
    console.error('Error in app.whenReady:', error);
  });

// TODO: Test single instance function in production
const mainWindow = getMainWindow(); // used to prevent multiple windows from running

if (mainWindow) {
  handleSingleInstance(mainWindow);
}

ipcMain.handle('reset-settings', resetSettings);
ipcMain.handle('load-settings', loadSettings);
ipcMain.handle('get-settings', getSettings);
ipcMain.handle('save-center-settings', saveCenterSettings);
ipcMain.handle('save-resize-settings', saveResizeSettings);
