import {
  createContext,
  useContext,
  useReducer,
  useEffect,
  useMemo,
  ReactNode,
} from 'react';

import defaultSettings from '@/constants/defaultSettings.json';

export interface WindowSizePercentage {
  width: number;
  height: number;
  x: number;
  y: number;
}

export interface Settings {
  centerWindow: {
    keybinding: string;
  };
  resizeWindow: {
    keybinding: string;
    windowSizePercentages: WindowSizePercentage[];
  };
}

interface SettingsContextProps extends Settings {
  settings: Settings;
  saveCenterSettings: (centerKeybind: string) => void;
  saveResizeSettings: (
    keybinding: string,
    windowSizePercentages: WindowSizePercentage[],
  ) => void;
  saveAllSettings: () => void;
  resetSettings: () => void;
}

export const SettingsContext = createContext<SettingsContextProps | null>(null);

export const useSettingsContext = () => {
  const context = useContext(SettingsContext);
  if (!context) {
    throw new Error(
      'useSettingsContext must be used within a SettingsProvider',
    );
  }
  return context;
};

type SettingsAction =
  | { type: 'LOAD_SETTINGS'; payload: Settings }
  | { type: 'SAVE_CENTER_SETTINGS'; payload: { centerKeybind: string } }
  | {
      type: 'SAVE_RESIZE_SETTINGS';
      payload: {
        keybinding: string;
        windowSizePercentages: WindowSizePercentage[];
      };
    }
  | { type: 'RESET_SETTINGS' };

function settingsReducer(state: Settings, action: SettingsAction): Settings {
  switch (action.type) {
    case 'LOAD_SETTINGS':
      return { ...state, ...action.payload };
    case 'SAVE_CENTER_SETTINGS':
      return {
        ...state,
        centerWindow: {
          ...state.centerWindow,
          keybinding: action.payload.centerKeybind,
        },
      };
    case 'SAVE_RESIZE_SETTINGS':
      return {
        ...state,
        resizeWindow: {
          ...state.resizeWindow,
          keybinding: action.payload.keybinding,
          windowSizePercentages: action.payload.windowSizePercentages,
        },
      };
    case 'RESET_SETTINGS':
      return defaultSettings as Settings;
    default:
      return state;
  }
}

function SettingsProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(
    settingsReducer,
    defaultSettings as Settings,
  );

  const loadSettings = async () => {
    const settings = await window.electron.ipcRenderer.invoke('get-settings');
    if (settings) {
      dispatch({
        type: 'LOAD_SETTINGS',
        payload: settings,
      });
    }
  };

  useEffect(() => {
    loadSettings();

    // Listen for settings changes from main process
    const unsubscribe = window.electron.ipcRenderer.on(
      'settings-changed',
      loadSettings,
    );

    return () => {
      unsubscribe();
    };
  }, []);

  const contextValue = useMemo(() => {
    const saveCenterSettings = async (centerKeybind: string) => {
      try {
        await window.electron.ipcRenderer.invoke(
          'save-center-settings',
          centerKeybind,
        );
        dispatch({ type: 'SAVE_CENTER_SETTINGS', payload: { centerKeybind } });
      } catch (error) {
        // eslint-disable-next-line no-console
        console.error('Error saving center settings:', error);
      }
    };

    const saveResizeSettings = async (
      keybinding: string,
      windowSizePercentages: WindowSizePercentage[],
    ) => {
      try {
        await window.electron.ipcRenderer.invoke('save-resize-settings', {
          keybinding,
          windowSizePercentages,
        });
        dispatch({
          type: 'SAVE_RESIZE_SETTINGS',
          payload: { keybinding, windowSizePercentages },
        });
      } catch (error) {
        // eslint-disable-next-line no-console
        console.error('Error saving resize settings:', error);
      }
    };

    const saveAllSettings = async () => {
      try {
        await window.electron.ipcRenderer.invoke('save-settings', state);
      } catch (error) {
        // eslint-disable-next-line no-console
        console.error('Error saving all settings:', error);
      }
    };

    const resetSettings = async () => {
      try {
        await window.electron.ipcRenderer.invoke('reset-settings');
        dispatch({ type: 'RESET_SETTINGS' });
      } catch (error) {
        // eslint-disable-next-line no-console
        console.error('Error resetting settings:', error);
      }
    };

    return {
      ...state,
      settings: state,
      saveCenterSettings,
      saveResizeSettings,
      saveAllSettings,
      resetSettings,
    };
  }, [state]);

  return (
    <SettingsContext.Provider value={contextValue}>
      {children}
    </SettingsContext.Provider>
  );
}

export default SettingsProvider;
