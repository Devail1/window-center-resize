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
  await fs.writeFile(settingsPath, JSON.stringify(defaultSettings));
  reloadAutoHotkey();
  mainWindow?.webContents.reload();
}

export async function loadSettings() {
  try {
    await ensureSettingsFileExists();
    reloadAutoHotkey();
  } catch (err) {
    handleError('Error loading settings', err);
  }
}

export async function getSettings() {
  try {
    const settings = await readSettingsFile();
    return settings;
  } catch (err) {
    handleError('Error getting settings', err);
    return null;
  }
}

export async function saveCenterSettings(
  _event: IpcMainInvokeEvent,
  centerKeybind: string,
) {
  try {
    const settings = await readSettingsFile();
    settings.centerWindow.keybinding = centerKeybind;
    await writeSettingsFile(settings);
  } catch (err) {
    handleError(`Error while saving center settings at ${settingsPath}`, err);
  }
}

export async function saveResizeSettings(
  _event: IpcMainInvokeEvent,
  data: {
    keybinding: string;
    windowSizePercentages: { width: string; height: string }[];
  },
) {
  try {
    const settings = await readSettingsFile();
    settings.resizeWindow = {
      keybinding: data.keybinding,
      windowSizePercentages: data.windowSizePercentages,
    };
    await writeSettingsFile(settings);
  } catch (err) {
    handleError(`Error while saving resize settings at ${settingsPath}`, err);
  }
}

export function closeWatcher() {
  if (settingsWatcher) {
    settingsWatcher.close();
  }
}
