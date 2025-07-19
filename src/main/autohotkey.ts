/* eslint no-console: off */

import * as child from 'child_process';
import { app } from 'electron';
import path from 'path';

let autohotkeyProcess: child.ChildProcess | null = null;

async function stopAutoHotkeyProcess() {
  if (autohotkeyProcess) {
    try {
      console.log('Stopping AutoHotkey process...');
      autohotkeyProcess.kill('SIGTERM');

      // Wait a bit for graceful shutdown
      await new Promise<void>((resolve) => {
        setTimeout(() => resolve(), 1000);
      });

      // Force kill if still running
      if (!autohotkeyProcess.killed) {
        console.log('Force killing AutoHotkey process...');
        autohotkeyProcess.kill('SIGKILL');
      }

      autohotkeyProcess = null;
      console.log('AutoHotkey process stopped');
    } catch (error) {
      console.error('Error killing AutoHotkey process:', error);
      autohotkeyProcess = null;
    }
  }
}

async function startAutoHotkeyProcess() {
  // Ensure the old process is stopped first
  await stopAutoHotkeyProcess();

  const { isPackaged } = app;

  const resourcesPath = isPackaged
    ? path.join(process.resourcesPath, 'assets', 'autohotkey')
    : path.join(__dirname, '../../assets', 'autohotkey');

  const autohotkeyPath = path.join(resourcesPath, 'AutoHotkey32.exe');
  const scriptPath = path.join(resourcesPath, 'center-window-resize.ahk');

  try {
    console.log('Starting AutoHotkey process...');
    autohotkeyProcess = child.spawn(autohotkeyPath, [scriptPath], {
      detached: false, // Keep attached so we can manage it
      stdio: 'ignore',
    });

    autohotkeyProcess.on('error', (error) => {
      console.error('AutoHotkey process error:', error);
    });

    autohotkeyProcess.on('exit', (code, signal) => {
      console.log(
        `AutoHotkey process exited with code ${code} and signal ${signal}`,
      );
      autohotkeyProcess = null;
    });

    console.log('AutoHotkey process started successfully');
  } catch (error) {
    console.error('Error starting AutoHotkey process:', error);
  }
}

async function reloadAutoHotkey() {
  console.log('Reloading AutoHotkey...');
  await startAutoHotkeyProcess();
}

export { startAutoHotkeyProcess, stopAutoHotkeyProcess, reloadAutoHotkey };
