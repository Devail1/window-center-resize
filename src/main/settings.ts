/* eslint no-console: off */

import { promises as fs, existsSync, watch, FSWatcher } from 'fs';
import { join } from 'path';
import { app, IpcMainInvokeEvent } from 'electron';
import defaultSettings from '../constants/defaultSettings.json';
import { reloadAutoHotkey } from './autohotkey';
import { getMainWindow } from './window';

const settingsPath = join(app.getPath('userData'), 'settings.json');

let settingsWatcher: FSWatcher;

export async function resetSettings() {
  const mainWindow = getMainWindow();
  await fs.writeFile(settingsPath, JSON.stringify(defaultSettings));
  reloadAutoHotkey();
  mainWindow?.reload();
}

export async function loadSettings() {
  try {
    if (!existsSync(settingsPath)) {
      await fs.writeFile(
        settingsPath,
        JSON.stringify(defaultSettings, null, 2),
      );
    }
    reloadAutoHotkey();
  } catch (err) {
    if (err instanceof Error) {
      console.error('Error loading settings:', err.message, err.stack);
    } else {
      console.error('Unknown error loading settings:', err);
    }
  }
}

export async function getSettings() {
  try {
    if (!existsSync(settingsPath)) {
      await fs.writeFile(
        settingsPath,
        JSON.stringify(defaultSettings, null, 2),
      );
    }
    const settings = JSON.parse(await fs.readFile(settingsPath, 'utf8'));
    return settings;
  } catch (err) {
    if (err instanceof Error) {
      console.error('Error getting settings:', err.message, err.stack);
    } else {
      console.error('Unknown error getting settings:', err);
    }
    return null;
  }
}

export async function saveCenterSettings(
  event: IpcMainInvokeEvent,
  centerKeybind: string,
) {
  try {
    const rawSettings = await fs.readFile(settingsPath, 'utf8');
    const settings = JSON.parse(rawSettings);
    settings.centerWindow.keybinding = centerKeybind;
    await fs.writeFile(settingsPath, JSON.stringify(settings, null, 2));

    reloadAutoHotkey();
  } catch (err) {
    if (err instanceof Error) {
      console.error('Error saving center settings:', err.message, err.stack);
    } else {
      console.error('Unknown error saving center settings:', err);
    }
  }
}

export async function saveResizeSettings(
  event: IpcMainInvokeEvent,
  data: {
    keybinding: string;
    windowSizePercentages: { width: string; height: string }[];
  },
) {
  try {
    const rawSettings = await fs.readFile(settingsPath, 'utf8');
    const settings = JSON.parse(rawSettings);
    settings.resizeWindow = {
      keybinding: data.keybinding,
      windowSizePercentages: data.windowSizePercentages,
    };
    await fs.writeFile(settingsPath, JSON.stringify(settings, null, 2));
    reloadAutoHotkey();
  } catch (err) {
    if (err instanceof Error) {
      console.error('Error saving resize settings:', err.message, err.stack);
    } else {
      console.error('Unknown error saving resize settings:', err);
    }
  }

  settingsWatcher = watch(settingsPath, () => {
    reloadAutoHotkey();
  });
}

export function closeWatcher() {
  if (settingsWatcher) {
    settingsWatcher.close();
  }
}
