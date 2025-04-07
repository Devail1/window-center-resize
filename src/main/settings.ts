/* eslint no-console: off */

import { promises as fs, existsSync, watch, FSWatcher } from 'fs';
import { join } from 'path';
import { app, IpcMainInvokeEvent } from 'electron';
import defaultSettings from '../constants/defaultSettings.json';
import { reloadAutoHotkey } from './autohotkey';
import { getMainWindow } from './window';

const settingsPath = join(app.getPath('userData'), 'settings.json');
let settingsWatcher: FSWatcher;

function handleError(message: string, err?: unknown) {
  if (err instanceof Error) {
    console.error(`${message}:`, err.message, err.stack);
  } else {
    console.error(`${message}: Unknown error`, err);
  }
}

function setupSettingsWatcher() {
  if (!settingsWatcher) {
    settingsWatcher = watch(settingsPath, () => {
      reloadAutoHotkey();
    });
  }
}

async function ensureSettingsFileExists() {
  if (!existsSync(settingsPath)) {
    await fs.writeFile(settingsPath, JSON.stringify(defaultSettings, null, 2));
  }
}

async function readSettingsFile() {
  await ensureSettingsFileExists();
  const rawSettings = await fs.readFile(settingsPath, 'utf8');
  return JSON.parse(rawSettings);
}

async function writeSettingsFile(settings: any) {
  await fs.writeFile(settingsPath, JSON.stringify(settings, null, 2));
  setupSettingsWatcher();
}

export async function resetSettings() {
  const mainWindow = getMainWindow();
  await fs.writeFile(settingsPath, JSON.stringify(defaultSettings, null, 2));
  reloadAutoHotkey();
  mainWindow?.webContents.reload();
}

export async function getSettings() {
  try {
    const settings = await readSettingsFile();
    return settings;
  } catch (err) {
    handleError('Error getting settings', err);
    return defaultSettings;
  }
}

export async function saveSettings(
  _event: IpcMainInvokeEvent,
  settings: {
    centerWindow?: {
      keybinding: string;
    };
    resizeWindow?: {
      keybinding: string;
      windowSizePercentages: {
        width: string;
        height: string;
        x: number;
        y: number;
      }[];
    };
  },
) {
  try {
    const currentSettings = await readSettingsFile();
    const updatedSettings = {
      ...currentSettings,
      ...(settings.centerWindow && { centerWindow: settings.centerWindow }),
      ...(settings.resizeWindow && { resizeWindow: settings.resizeWindow }),
    };
    await writeSettingsFile(updatedSettings);
  } catch (err) {
    handleError(`Error while saving settings at ${settingsPath}`, err);
  }
}

// Deprecated - use saveSettings instead
export async function saveCenterSettings(
  _event: IpcMainInvokeEvent,
  centerKeybind: string,
) {
  return saveSettings(_event, { centerWindow: { keybinding: centerKeybind } });
}

// Deprecated - use saveSettings instead
export async function saveResizeSettings(
  _event: IpcMainInvokeEvent,
  data: {
    keybinding: string;
    windowSizePercentages: { width: string; height: string }[];
  },
) {
  const resizeData = {
    ...data,
    windowSizePercentages: data.windowSizePercentages.map((size) => ({
      ...size,
      x: 0,
      y: 0,
    })),
  };
  return saveSettings(_event, { resizeWindow: resizeData });
}

export function closeWatcher() {
  if (settingsWatcher) {
    settingsWatcher.close();
  }
}
