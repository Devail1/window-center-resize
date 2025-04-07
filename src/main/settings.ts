/* eslint no-console: off */

import { promises as fs, existsSync, watch, FSWatcher } from 'fs';
import { join } from 'path';
import { app, IpcMainInvokeEvent } from 'electron';
import defaultSettings from '../constants/defaultSettings.json';
import { reloadAutoHotkey } from './autohotkey';
import { getMainWindow } from './window';

interface Settings {
  centerWindow: {
    keybinding: string;
  };
  resizeWindow: {
    keybinding: string;
    windowSizePercentages: Array<{
      width: number;
      height: number;
      x: number;
      y: number;
    }>;
  };
}

const settingsPath = join(app.getPath('userData'), 'settings.json');
let settingsWatcher: FSWatcher;
let isWritingSettings = false;

function handleError(message: string, err?: unknown) {
  if (err instanceof Error) {
    console.error(`${message}:`, err.message, err.stack);
  } else {
    console.error(`${message}: Unknown error`, err);
  }
}

function setupSettingsWatcher() {
  if (!settingsWatcher) {
    settingsWatcher = watch(settingsPath, (eventType) => {
      // Only reload if the change wasn't triggered by our own write
      if (eventType === 'change' && !isWritingSettings) {
        reloadAutoHotkey();
      }
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
  isWritingSettings = true;
  try {
    await fs.writeFile(settingsPath, JSON.stringify(settings, null, 2));
    setupSettingsWatcher();
  } finally {
    isWritingSettings = false;
  }
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
  settings: Settings,
) {
  try {
    await writeSettingsFile(settings);
    reloadAutoHotkey();
    const mainWindow = getMainWindow();
    mainWindow?.webContents.send('settings-changed');
  } catch (err) {
    handleError(`Error while saving settings at ${settingsPath}`, err);
  }
}

export async function saveCenterSettings(
  _event: IpcMainInvokeEvent,
  centerKeybind: string,
) {
  try {
    const currentSettings = await readSettingsFile();
    currentSettings.centerWindow.keybinding = centerKeybind;
    await writeSettingsFile(currentSettings);
  } catch (err) {
    handleError(`Error while saving center settings at ${settingsPath}`, err);
  }
}

export async function saveResizeSettings(
  _event: IpcMainInvokeEvent,
  data: {
    keybinding: string;
    windowSizePercentages: Array<{
      width: number;
      height: number;
      x: number;
      y: number;
    }>;
  },
) {
  try {
    const currentSettings = await readSettingsFile();
    currentSettings.resizeWindow = data;
    await writeSettingsFile(currentSettings);
  } catch (err) {
    handleError(`Error while saving resize settings at ${settingsPath}`, err);
  }
}

export function closeWatcher() {
  if (settingsWatcher) {
    settingsWatcher.close();
  }
}
