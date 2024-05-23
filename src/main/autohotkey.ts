import * as child from 'child_process';
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

  const resourcesPath = path.join(__dirname, '../../assets');

  // path.join(process.cwd(), '/assets');
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

function reloadAutoHotkey() {
  if (autohotkeyProcess) {
    stopAutoHotkeyProcess();
  }
  startAutoHotkeyProcess();
}

export { startAutoHotkeyProcess, stopAutoHotkeyProcess, reloadAutoHotkey };
