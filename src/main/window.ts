import { app, BrowserWindow, Menu, Notification, Tray } from 'electron';
import { getSettings } from './settings';
import { getIconPath } from './util';

let mainWindow: BrowserWindow;

function createWindow(): BrowserWindow {
  mainWindow = new BrowserWindow({
    width: 580,
    height: 760,
    icon: getIconPath('logo'),
    autoHideMenuBar: true,
    show: false,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
    },
  });

  mainWindow.loadFile('index.html');

  mainWindow.on('close', (event) => {
    if (mainWindow.isVisible()) {
      event.preventDefault();
      mainWindow.hide();
    }
  });

  return mainWindow;
}

async function showNotification() {
  const settings = await getSettings();
  if (settings) {
    const { centerWindow, resizeWindow } = settings;

    const notification = new Notification({
      title: 'Window Snapper',
      body: `Press ${centerWindow.keybinding} to center the window. \nPress ${resizeWindow.keybinding} to resize the window.`,
      silent: true,
    });

    notification.on('click', () => {
      mainWindow.show();
    });

    notification.show();
  }
}

function createTrayMenu(tray: Tray) {
  const contextMenu = Menu.buildFromTemplate([
    {
      label: 'Open',
      click: () => mainWindow.show(),
      icon: getIconPath('open'),
    },
    {
      label: 'Quit',
      click: () => app.quit(),
      icon: getIconPath('quit'),
    },
  ]);

  contextMenu.items.forEach((item) => {
    item.enabled = true;
    item.visible = true;
    item.icon = 'icon-quit';
  });
  tray.setToolTip('Window Snapper');
  tray.setContextMenu(contextMenu);
  tray.on('click', () => mainWindow.show());

  showNotification();
}

export { createWindow, createTrayMenu };
