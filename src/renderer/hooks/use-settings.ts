import { useState, useEffect, useCallback } from 'react';

interface Preset {
  id: string;
  name: string;
  x: number;
  y: number;
  width: number;
  height: number;
  shortcut: string;
  unit: 'px' | '%';
  enabled: boolean;
}

interface ToggleGroup {
  id: string;
  name: string;
  shortcut: string;
  presetIds: string[];
  currentIndex: number;
  enabled: boolean;
}

interface AppSettings {
  centeringEnabled: boolean;
  resizingEnabled: boolean;
  positioningEnabled: boolean;
  startWithWindows: boolean;
  showNotifications: boolean;
  darkMode: boolean;
}

interface Settings {
  presets: Preset[];
  toggleGroups: ToggleGroup[];
  settings: AppSettings;
  legacy?: {
    centerWindow: {
      keybinding: string;
    };
    resizeWindow: {
      keybinding: string;
      windowSizePercentages: Array<{
        width: number;
        height: number;
        x: number;
        y: number;
      }>;
    };
  };
}

export function useSettings() {
  const [settings, setSettings] = useState<Settings | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Load settings from Electron
  const loadSettings = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      if (window.electronAPI) {
        const data = await window.electronAPI.getSettings();
        setSettings(data);
      } else {
        // Fallback for development without Electron
        setSettings({
          presets: [
            {
              id: '1',
              name: 'Center Large',
              x: 20,
              y: 10,
              width: 60,
              height: 80,
              shortcut: 'Ctrl+Alt+C',
              unit: '%',
              enabled: true,
            },
            {
              id: '2',
              name: 'Left Half',
              x: 0,
              y: 0,
              width: 50,
              height: 100,
              shortcut: 'Ctrl+Alt+L',
              unit: '%',
              enabled: true,
            },
            {
              id: '3',
              name: 'Right Half',
              x: 50,
              y: 0,
              width: 50,
              height: 100,
              shortcut: 'Ctrl+Alt+R',
              unit: '%',
              enabled: false,
            },
          ],
          toggleGroups: [
            {
              id: '1',
              name: 'Work Layout',
              shortcut: 'Ctrl+Alt+Tab',
              presetIds: ['1', '2'],
              currentIndex: 0,
              enabled: true,
            },
            {
              id: '2',
              name: 'Split Views',
              shortcut: 'Ctrl+Alt+Space',
              presetIds: ['2', '3'],
              currentIndex: 0,
              enabled: true,
            },
          ],
          settings: {
            centeringEnabled: true,
            resizingEnabled: true,
            positioningEnabled: true,
            startWithWindows: false,
            showNotifications: true,
            darkMode: false,
          },
        });
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load settings');
    } finally {
      setLoading(false);
    }
  }, []);

  // Save all settings
  const saveSettings = useCallback(async (newSettings: Settings) => {
    try {
      if (window.electronAPI) {
        await window.electronAPI.saveSettings(newSettings);
      }
      setSettings(newSettings);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save settings');
      throw err;
    }
  }, []);

  // Save presets
  const savePresets = useCallback(async (presets: Preset[]) => {
    try {
      if (window.electronAPI) {
        await window.electronAPI.savePresets(presets);
      }
      setSettings((prev) => (prev ? { ...prev, presets } : null));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save presets');
      throw err;
    }
  }, []);

  // Save toggle groups
  const saveToggleGroups = useCallback(async (toggleGroups: ToggleGroup[]) => {
    try {
      if (window.electronAPI) {
        await window.electronAPI.saveToggleGroups(toggleGroups);
      }
      setSettings((prev) => (prev ? { ...prev, toggleGroups } : null));
    } catch (err) {
      setError(
        err instanceof Error ? err.message : 'Failed to save toggle groups',
      );
      throw err;
    }
  }, []);

  // Save app settings
  const saveAppSettings = useCallback(async (appSettings: AppSettings) => {
    try {
      if (window.electronAPI) {
        await window.electronAPI.saveAppSettings(appSettings);
      }
      setSettings((prev) => (prev ? { ...prev, settings: appSettings } : null));
    } catch (err) {
      setError(
        err instanceof Error ? err.message : 'Failed to save app settings',
      );
      throw err;
    }
  }, []);

  // Reset settings
  const resetSettings = useCallback(async () => {
    try {
      if (window.electronAPI) {
        await window.electronAPI.resetSettings();
      }
      await loadSettings();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to reset settings');
      throw err;
    }
  }, [loadSettings]);

  // Listen for settings changes from main process
  useEffect(() => {
    if (window.electronAPI) {
      const unsubscribe = window.electronAPI.onSettingsChanged(() => {
        loadSettings();
      });
      return unsubscribe;
    }
    return undefined;
  }, [loadSettings]);

  // Load settings on mount
  useEffect(() => {
    loadSettings();
  }, [loadSettings]);

  return {
    settings,
    loading,
    error,
    saveSettings,
    savePresets,
    saveToggleGroups,
    saveAppSettings,
    resetSettings,
    loadSettings,
  };
}
