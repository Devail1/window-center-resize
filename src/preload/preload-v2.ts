import { contextBridge, ipcRenderer } from 'electron';

// Expose protected methods that allow the renderer process to use
// the ipcRenderer without exposing the entire object
contextBridge.exposeInMainWorld('electronAPI', {
  // Settings
  getSettings: () => ipcRenderer.invoke('get-settings'),
  saveSettings: (settings: any) =>
    ipcRenderer.invoke('save-settings', settings),
  savePresets: (presets: any[]) => ipcRenderer.invoke('save-presets', presets),
  saveToggleGroups: (toggleGroups: any[]) =>
    ipcRenderer.invoke('save-toggle-groups', toggleGroups),
  saveAppSettings: (appSettings: any) =>
    ipcRenderer.invoke('save-app-settings', appSettings),
  resetSettings: () => ipcRenderer.invoke('reset-settings'),

  // Legacy settings (for backward compatibility)
  saveCenterSettings: (keybinding: string) =>
    ipcRenderer.invoke('save-center-settings', keybinding),
  saveResizeSettings: (data: any) =>
    ipcRenderer.invoke('save-resize-settings', data),

  // Screen info
  getScreenSize: () => ipcRenderer.invoke('get-screen-size'),

  // Apply preset
  applyPreset: (preset: any) => ipcRenderer.invoke('apply-preset', preset),

  // Events
  onSettingsChanged: (callback: () => void) => {
    ipcRenderer.on('settings-changed', callback);
    return () => {
      ipcRenderer.removeAllListeners('settings-changed');
    };
  },
});

// Type definitions for TypeScript
declare global {
  interface Window {
    electronAPI: {
      getSettings: () => Promise<any>;
      saveSettings: (settings: any) => Promise<void>;
      savePresets: (presets: any[]) => Promise<void>;
      saveToggleGroups: (toggleGroups: any[]) => Promise<void>;
      saveAppSettings: (appSettings: any) => Promise<void>;
      resetSettings: () => Promise<void>;
      saveCenterSettings: (keybinding: string) => Promise<void>;
      saveResizeSettings: (data: any) => Promise<void>;
      getScreenSize: () => Promise<{ width: number; height: number }>;
      onSettingsChanged: (callback: () => void) => () => void;
    };
  }
}
