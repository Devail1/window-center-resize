import { useEffect, useState } from 'react';
import Store from 'electron-store';
import { CustomStore } from '../../main/preload';

interface WindowSizePercentage {
  width: string;
  height: string;
}

interface Settings {
  centerWindow: {
    keybinding: string;
  };
  resizeWindow: {
    keybinding: string;
    windowSizePercentages: WindowSizePercentage[];
  };
}

// Create a new instance of electron-store
const store = new Store() as CustomStore;

export default function useSettings(): {
  settings: Settings | null;
  saveCenterSettings: (centerKeybind: string) => void;
  saveResizeSettings: (
    resizeKeybind: string,
    windowSizePercentages: WindowSizePercentage[],
  ) => void;
  resetSettings: () => void;
} {
  const [settings, setSettings] = useState<Settings | null>(null);

  useEffect(() => {
    // Load settings from the store
    const loadedSettings = {
      centerWindow: {
        keybinding: store.get('centerWindowKeybinding') || '',
      },
      resizeWindow: {
        keybinding: store.get('resizeWindowKeybinding') || '',
        windowSizePercentages: store.get('resizeWindowPercentages') || [],
      },
    };
    setSettings(loadedSettings);
  }, []);

  const saveCenterSettings = (centerKeybind: string) => {
    // Save center keybind to the store
    store.set('centerWindowKeybinding', centerKeybind);
  };

  const saveResizeSettings = (
    resizeKeybind: string,
    windowSizePercentages: WindowSizePercentage[],
  ) => {
    // Save resize keybind and window size percentages to the store
    store.set('resizeWindowKeybinding', resizeKeybind);
    store.set('resizeWindowPercentages', windowSizePercentages);
  };

  const resetSettings = () => {
    // Reset settings in the store
    store.delete('centerWindowKeybinding');
    store.delete('resizeWindowKeybinding');
    store.delete('resizeWindowPercentages');
  };

  return {
    settings,
    saveCenterSettings,
    saveResizeSettings,
    resetSettings,
  };
}
