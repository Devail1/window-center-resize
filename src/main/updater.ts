/* eslint-disable no-console */

import { autoUpdater } from 'electron-updater';
import log from 'electron-log';
import { dialog, shell } from 'electron';

export const startAppUpdater = () => {
  autoUpdater.channel = 'beta';

  log.transports.file.level = 'info';
  autoUpdater.logger = log;

  autoUpdater.on('checking-for-update', () => {
    log.info('Checking for update...');
  });

  autoUpdater.on('update-available', (info) => {
    log.info('Update available:', info);
  });

  autoUpdater.on('update-not-available', (info) => {
    log.info('Update not available:', info);
  });

  autoUpdater.on('error', (err) => {
    log.error('Error in auto-updater:', err);
  });

  autoUpdater.on('download-progress', (progressObj) => {
    let logMessage = `Download speed: ${progressObj.bytesPerSecond}`;
    logMessage += ` - Downloaded ${progressObj.percent}%`;
    logMessage += ` (${progressObj.transferred}/${progressObj.total})`;
    log.info(logMessage);
  });

  autoUpdater.on('update-downloaded', (info) => {
    log.info('Update downloaded', info);
    dialog
      .showMessageBox({
        type: 'info',
        title: 'Update Available',
        message:
          'A new version is available. Please download the latest version to update.',
        buttons: ['Download', 'Later'],
      })
      .then((result) => {
        const buttonIndex = result.response;
        if (buttonIndex === 0) {
          shell.openExternal(
            'https://github.com/devail1/window-center-resize/releases/latest/download/Window-Center-Resize.exe',
          );
        }
        return null;
      })
      .catch((error) => {
        console.error('Error in update notification:', error);
      });
  });

  autoUpdater.checkForUpdatesAndNotify();
};
