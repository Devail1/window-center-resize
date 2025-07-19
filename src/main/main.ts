/* eslint no-console: off */

import { BrowserWindow, app, ipcMain, screen } from 'electron';
import sourceMapSupport from 'source-map-support';
import debug from 'electron-debug';
import { spawn } from 'child_process';
import path from 'path';
import { startAutoHotkeyProcess, stopAutoHotkeyProcess } from './autohotkey';
import { createWindow } from './window';
import {
  resetSettings,
  saveCenterSettings,
  saveResizeSettings,
  saveSettings,
  savePresets,
  saveToggleGroups,
  saveAppSettings,
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
      ipcMain.handle('save-presets', savePresets);
      ipcMain.handle('save-toggle-groups', saveToggleGroups);
      ipcMain.handle('save-app-settings', saveAppSettings);
      ipcMain.handle('apply-preset', async (_event, preset) => {
        try {
          // Call AutoHotkey script directly with the preset ID
          const autohotkeyPath = path.join(
            __dirname,
            '../../assets/autohotkey/AutoHotkey32.exe',
          );
          const scriptPath = path.join(
            __dirname,
            '../../assets/autohotkey/center-window-resize.ahk',
          );
          const command = `APPLY_PRESET:${preset.id}`;

          console.log('Calling AutoHotkey with command:', command);

          const child = spawn(autohotkeyPath, [scriptPath, command], {
            detached: true,
            stdio: 'ignore',
          });

          child.unref(); // Don't wait for the process to finish

          return { success: true };
        } catch (error) {
          console.error('Error applying preset:', error);
          return { success: false, error: (error as Error).message };
        }
      });
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

        // Force quit to ensure all processes are terminated
        app.exit(0);
      });

      // Handle window closed event
      app.on('window-all-closed', () => {
        // Don't quit the app on macOS when all windows are closed
        if (process.platform !== 'darwin') {
          app.quit();
        }
      });

      // Handle before-quit event for additional cleanup
      app.on('before-quit', () => {
        // Close all windows
        BrowserWindow.getAllWindows().forEach((window) => {
          if (!window.isDestroyed()) {
            window.destroy();
          }
        });
      });

      startAppUpdater();
      return null;
    })
    .catch((error) => {
      console.error('Error in app.whenReady:', error);
    });
}
