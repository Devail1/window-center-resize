/* eslint no-console: off */

import * as child from 'child_process';
import { app } from 'electron';
import path from 'path';

let autohotkeyProcess: child.ChildProcess | null = null;

async function stopAutoHotkeyProcess() {
  if (autohotkeyProcess) {
    try {
      autohotkeyProcess.kill();
      autohotkeyProcess.on('exit', () => {
        autohotkeyProcess = null;
      });
    } catch (error) {
      console.error('Error killing AutoHotkey process:', error);
    }
  }
}

async function startAutoHotkeyProcess() {
  if (autohotkeyProcess) {
    await stopAutoHotkeyProcess();
  }

  const { isPackaged } = app;

  const resourcesPath = isPackaged
    ? path.join(process.resourcesPath, 'assets', 'autohotkey')
    : path.join(__dirname, '../../assets', 'autohotkey');

  const autohotkeyPath = path.join(resourcesPath, 'AutoHotkey32.exe');
  const scriptPath = path.join(resourcesPath, 'center-window-resize.ahk');

  try {
    autohotkeyProcess = child.spawn(autohotkeyPath, [scriptPath]);
  } catch (error) {
    console.error('Error starting AutoHotkey process:', error);
  }
}

async function reloadAutoHotkey() {
  await startAutoHotkeyProcess();
}

export { startAutoHotkeyProcess, stopAutoHotkeyProcess, reloadAutoHotkey };
