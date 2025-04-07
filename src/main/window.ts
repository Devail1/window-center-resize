/* eslint global-require: off, no-console: off */

import { app, BrowserWindow, shell } from 'electron';
import path from 'path';
import { getIconPath, resolveHtmlPath } from './util';
import { handleSingleInstance } from './singleInstance';

let mainWindow: BrowserWindow | null = null;

export const createWindow = async (): Promise<BrowserWindow> => {
  mainWindow = new BrowserWindow({
    width: 580,
    height: 640,
    icon: getIconPath('logo'),
    show: false,
    autoHideMenuBar: true,
    webPreferences: {
      nodeIntegration: true,
      preload: app.isPackaged
        ? path.join(__dirname, 'preload.js')
        : path.join(__dirname, '../../.erb/dll/preload.js'),
    },
  });

  mainWindow.loadURL(resolveHtmlPath('index.html'));

  mainWindow.on('close', (event) => {
    if (mainWindow?.isVisible()) {
      event.preventDefault();
      mainWindow.hide();
    }
  });

  mainWindow.on('closed', () => {
    mainWindow = null;
  });

  mainWindow.webContents.setWindowOpenHandler((edata) => {
    shell.openExternal(edata.url);
    return { action: 'deny' };
  });

  handleSingleInstance(mainWindow);

  return mainWindow;
};

export const getMainWindow = (): BrowserWindow | null => mainWindow;
