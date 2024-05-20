import { promises as fs, existsSync, watch, FSWatcher } from 'fs';
import { join } from 'path';
import { app, IpcMainInvokeEvent } from 'electron';
import defaultSettings from '../constants/defaultSettings.json';
import { startAutoHotkeyProcess, stopAutoHotkeyProcess } from './autohotkey';

const settingsPath = join(app.getPath('userData'), 'settings.json');
let settingsWatcher: FSWatcher;

export async function resetSettings(event: IpcMainInvokeEvent) {
  event.sender.send('load-settings-reply', { settings: defaultSettings });
  await fs.writeFile(settingsPath, JSON.stringify(defaultSettings));
  stopAutoHotkeyProcess();
  startAutoHotkeyProcess();
}

export async function loadSettings(event: IpcMainInvokeEvent) {
  try {
    if (!existsSync(settingsPath)) {
      await fs.writeFile(
        settingsPath,
        JSON.stringify(defaultSettings, null, 2),
      );
    }
    const settings = JSON.parse(await fs.readFile(settingsPath, 'utf8'));
    event.sender.send('load-settings-reply', { settings });
    stopAutoHotkeyProcess();
    startAutoHotkeyProcess();
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
  data: { centerKeybind: string },
) {
  try {
    const rawSettings = await fs.readFile(settingsPath, 'utf8');
    const settings = JSON.parse(rawSettings);
    settings.centerWindow.keybinding = data.centerKeybind;
    await fs.writeFile(settingsPath, JSON.stringify(settings, null, 2));
    stopAutoHotkeyProcess();
    startAutoHotkeyProcess();
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
    resizeKeybind: string;
    windowSizePercentages: { width: string; height: string }[];
  },
) {
  try {
    const rawSettings = await fs.readFile(settingsPath, 'utf8');
    const settings = JSON.parse(rawSettings);
    settings.resizeWindow = {
      keybinding: data.resizeKeybind,
      windowSizePercentages: data.windowSizePercentages,
    };
    await fs.writeFile(settingsPath, JSON.stringify(settings, null, 2));
    stopAutoHotkeyProcess();
    startAutoHotkeyProcess();
  } catch (err) {
    if (err instanceof Error) {
      console.error('Error saving resize settings:', err.message, err.stack);
    } else {
      console.error('Unknown error saving resize settings:', err);
    }
  }

  settingsWatcher = watch(settingsPath, () => {
    stopAutoHotkeyProcess();
    startAutoHotkeyProcess();
  });
}

export function closeWatcher() {
  if (settingsWatcher) {
    settingsWatcher.close();
  }
}
