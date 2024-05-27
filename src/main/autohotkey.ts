/* eslint no-console: off */

import * as child from 'child_process';
import { app } from 'electron';
import path from 'path';

let autohotkeyProcess: child.ChildProcess | null = null;

async function stopAutoHotkeyProcess() {
  if (autohotkeyProcess) {
    try {
      await autohotkeyProcess.kill();
    } catch (error) {
      console.error('Error killing child process:', error);
    }
    autohotkeyProcess = null;
  }
}

async function startAutoHotkeyProcess() {
  if (autohotkeyProcess) {
    stopAutoHotkeyProcess();
  }

  const { isPackaged } = app;

  const resourcesPath = isPackaged
    ? path.join(process.resourcesPath, 'assets', 'autohotkey')
    : path.join(__dirname, '../../assets', 'autohotkey');

  const autohotkeyPath = path.join(resourcesPath, 'AutoHotkey32.exe');
  const scriptPath = path.join(resourcesPath, 'center-window-resize.ahk');

  console.log('AutoHotkey Path:', autohotkeyPath);
  console.log('Script Path:', scriptPath);

  try {
    autohotkeyProcess = child.spawn(autohotkeyPath, [scriptPath]);
  } catch (error) {
    console.error('Unexpected error spawning AutoHotkey:', error);
  }
}

function reloadAutoHotkey() {
  if (autohotkeyProcess) {
    stopAutoHotkeyProcess();
  }
  startAutoHotkeyProcess();
}

export { startAutoHotkeyProcess, stopAutoHotkeyProcess, reloadAutoHotkey };
