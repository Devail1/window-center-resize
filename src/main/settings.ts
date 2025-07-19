/* eslint no-console: off */

import { promises as fs, existsSync, watch, FSWatcher } from 'fs';
import { join } from 'path';
import { app, IpcMainInvokeEvent } from 'electron';
import defaultSettings from '../constants/defaultSettings.json';
import { reloadAutoHotkey } from './autohotkey';
import { getMainWindow } from './window';

interface Preset {
  id: string;
  name: string;
  x: number;
  y: number;
  width: number;
  height: number;
  shortcut: string;
  unit: 'px' | '%';
  enabled: boolean;
}

interface ToggleGroup {
  id: string;
  name: string;
  shortcut: string;
  presetIds: string[];
  currentIndex: number;
  enabled: boolean;
}

interface AppSettings {
  centeringEnabled: boolean;
  resizingEnabled: boolean;
  positioningEnabled: boolean;
  startWithWindows: boolean;
  showNotifications: boolean;
  darkMode: boolean;
}

interface Settings {
  presets: Preset[];
  toggleGroups: ToggleGroup[];
  settings: AppSettings;
  legacy: {
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

export async function savePresets(
  _event: IpcMainInvokeEvent,
  presets: Preset[],
) {
  try {
    const currentSettings = await readSettingsFile();
    currentSettings.presets = presets;
    await writeSettingsFile(currentSettings);
    reloadAutoHotkey();
    const mainWindow = getMainWindow();
    mainWindow?.webContents.send('settings-changed');
  } catch (err) {
    handleError(`Error while saving presets at ${settingsPath}`, err);
  }
}

export async function saveToggleGroups(
  _event: IpcMainInvokeEvent,
  toggleGroups: ToggleGroup[],
) {
  try {
    const currentSettings = await readSettingsFile();
    currentSettings.toggleGroups = toggleGroups;
    await writeSettingsFile(currentSettings);
    reloadAutoHotkey();
    const mainWindow = getMainWindow();
    mainWindow?.webContents.send('settings-changed');
  } catch (err) {
    handleError(`Error while saving toggle groups at ${settingsPath}`, err);
  }
}

export async function saveAppSettings(
  _event: IpcMainInvokeEvent,
  appSettings: AppSettings,
) {
  try {
    const currentSettings = await readSettingsFile();
    currentSettings.settings = appSettings;
    await writeSettingsFile(currentSettings);
    reloadAutoHotkey();
    const mainWindow = getMainWindow();
    mainWindow?.webContents.send('settings-changed');
  } catch (err) {
    handleError(`Error while saving app settings at ${settingsPath}`, err);
  }
}

export async function saveCenterSettings(
  _event: IpcMainInvokeEvent,
  centerKeybind: string,
) {
  try {
    const currentSettings = await readSettingsFile();
    currentSettings.legacy.centerWindow.keybinding = centerKeybind;
    await writeSettingsFile(currentSettings);
    reloadAutoHotkey();
    const mainWindow = getMainWindow();
    mainWindow?.webContents.send('settings-changed');
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
    currentSettings.legacy.resizeWindow = data;
    await writeSettingsFile(currentSettings);
    reloadAutoHotkey();
    const mainWindow = getMainWindow();
    mainWindow?.webContents.send('settings-changed');
  } catch (err) {
    handleError(`Error while saving resize settings at ${settingsPath}`, err);
  }
}

export function closeWatcher() {
  if (settingsWatcher) {
    settingsWatcher.close();
  }
}
