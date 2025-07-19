import { ElectronHandler } from '../main/preload';

declare global {
  // eslint-disable-next-line no-unused-vars
  interface Window {
    electron: ElectronHandler;
    electronAPI: {
      getSettings: () => Promise<any>;
      resetSettings: () => Promise<void>;
      saveCenterSettings: (keybinding: string) => Promise<void>;
      saveResizeSettings: (data: any) => Promise<void>;
      saveSettings: (settings: any) => Promise<void>;
      savePresets: (presets: any) => Promise<void>;
      saveToggleGroups: (toggleGroups: any) => Promise<void>;
      saveAppSettings: (appSettings: any) => Promise<void>;
      applyPreset: (
        preset: any,
      ) => Promise<{ success: boolean; error?: string }>;
      getScreenSize: () => Promise<{ width: number; height: number }>;
      onSettingsChanged: (callback: () => void) => () => void;
    };
  }
}

export {};
