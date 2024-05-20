import * as child from 'child_process';
import path from 'path';

let autohotkeyProcess: child.ChildProcess | null = null;

async function startAutoHotkeyProcess() {
  if (autohotkeyProcess) {
    try {
      await autohotkeyProcess.kill();
    } catch (error) {
      console.error('Error killing child process:', error);
    }
  }
  const resourcesPath = path.join(process.cwd(), '/assets');
  const autohotkeyPath = path.join(
    resourcesPath,
    'autohotkey',
    'AutoHotkey32.exe',
  );
  const scriptPath = path.join(
    resourcesPath,
    'autohotkey',
    'center-window-resize.ahk',
  );

  try {
    autohotkeyProcess = child.spawn(autohotkeyPath, [scriptPath]);
  } catch (error) {
    console.error('Unexpected error spawning AutoHotkey:', error);
  }
}

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

export { startAutoHotkeyProcess, stopAutoHotkeyProcess };
