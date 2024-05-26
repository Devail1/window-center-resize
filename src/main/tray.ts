import { app, Menu, Notification, Tray } from 'electron';
import { capitalizeFirstLetterOfEachWord, getIconPath } from './util';
import { getSettings } from './settings';
import { getMainWindow } from './window';

let tray: Tray | null = null;

const showNotification = async (): Promise<void> => {
  const settings = await getSettings();
  if (settings) {
    const { centerWindow, resizeWindow } = settings;

    const notification = new Notification({
      title: 'Window Snapper',
      body: `Press ${capitalizeFirstLetterOfEachWord(centerWindow.keybinding)} to center the window. \nPress ${capitalizeFirstLetterOfEachWord(resizeWindow.keybinding)} to resize the window.`,
      silent: true,
    });

    notification.on('click', () => {
      getMainWindow()?.show();
    });

    notification.show();
  }
};

const createTrayMenu = (): void => {
  tray = new Tray(getIconPath('logo'));

  const contextMenu = Menu.buildFromTemplate([
    {
      label: 'Open',
      click: () => getMainWindow()?.show(),
      icon: getIconPath('open'),
    },
    {
      label: 'Quit',
      click: () => app.quit(),
      icon: getIconPath('quit'),
    },
  ]);

  tray.setToolTip('Window Snapper');
  tray.setContextMenu(contextMenu);
  tray.on('click', () => getMainWindow()?.show());

  showNotification();
};

export default createTrayMenu;
