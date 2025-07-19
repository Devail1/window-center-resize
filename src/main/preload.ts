// Disable no-unused-vars, broken for spread args
/* eslint no-unused-vars: off */
import { contextBridge, ipcRenderer, IpcRendererEvent } from 'electron';

export type Channels =
  | 'get-settings'
  | 'reset-settings'
  | 'save-center-settings'
  | 'save-resize-settings'
  | 'save-settings'
  | 'settings-changed'
  | 'get-screen-size';

const electronHandler = {
  ipcRenderer: {
    sendMessage(channel: Channels, ...args: unknown[]) {
      ipcRenderer.send(channel, ...args);
    },
    on(channel: Channels, func: (...args: unknown[]) => void) {
      const subscription = (_event: IpcRendererEvent, ...args: unknown[]) =>
        func(...args);
      ipcRenderer.on(channel, subscription);

      return () => {
        ipcRenderer.removeListener(channel, subscription);
      };
    },
    once(channel: Channels, func: (...args: unknown[]) => void) {
      ipcRenderer.once(channel, (_event, ...args) => func(...args));
    },
    invoke(channel: Channels, ...args: unknown[]) {
      return ipcRenderer.invoke(channel, ...args);
    },
    removeAllListeners(channel: Channels) {
      ipcRenderer.removeAllListeners(channel);
    },
  },
};

// Create the electronAPI object that the renderer expects
const electronAPI = {
  getSettings: () => ipcRenderer.invoke('get-settings'),
  resetSettings: () => ipcRenderer.invoke('reset-settings'),
  saveCenterSettings: (keybinding: string) =>
    ipcRenderer.invoke('save-center-settings', keybinding),
  saveResizeSettings: (data: any) =>
    ipcRenderer.invoke('save-resize-settings', data),
  saveSettings: (settings: any) =>
    ipcRenderer.invoke('save-settings', settings),
  savePresets: (presets: any) => ipcRenderer.invoke('save-presets', presets),
  saveToggleGroups: (toggleGroups: any) =>
    ipcRenderer.invoke('save-toggle-groups', toggleGroups),
  saveAppSettings: (appSettings: any) =>
    ipcRenderer.invoke('save-app-settings', appSettings),
  applyPreset: (preset: any) => ipcRenderer.invoke('apply-preset', preset),
  onSettingsChanged: (callback: () => void) => {
    const subscription = () => callback();
    ipcRenderer.on('settings-changed', subscription);
    return () => {
      ipcRenderer.removeListener('settings-changed', subscription);
    };
  },
};

// Only expose the handler if we're in a sandboxed environment
if (process.contextIsolated) {
  contextBridge.exposeInMainWorld('electron', electronHandler);
  contextBridge.exposeInMainWorld('electronAPI', electronAPI);
} else {
  // @ts-ignore (define in dts)
  window.electron = electronHandler;
  // @ts-ignore (define in dts)
  window.electronAPI = electronAPI;
}

export type ElectronHandler = typeof electronHandler;
