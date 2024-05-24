import React, {
  createContext,
  useContext,
  useReducer,
  useEffect,
  useMemo,
  ReactNode,
} from 'react';

import defaultSettings from '../../constants/defaultSettings.json';

// Define the shape of your settings
export interface WindowSizePercentage {
  width: string;
  height: string;
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
      return defaultSettings;
    default:
      return state;
  }
}

function SettingsProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(settingsReducer, defaultSettings);

  useEffect(() => {
    const loadSettings = async () => {
      const settings = await window.electron.ipcRenderer.invoke('get-settings');

      dispatch({ type: 'LOAD_SETTINGS', payload: settings });
    };

    loadSettings();

    window.electron.ipcRenderer.on(
      'settings-updated',
      (event, updatedSettings: any) => {
        dispatch({ type: 'LOAD_SETTINGS', payload: updatedSettings });
      },
    );

    return () => {
      window.electron.ipcRenderer.removeAllListeners('settings-updated');
    };
  }, []);

  const saveCenterSettings = (centerKeybind: string) => {
    window.electron.ipcRenderer.invoke('save-center-settings', centerKeybind);
    dispatch({ type: 'SAVE_CENTER_SETTINGS', payload: { centerKeybind } });
  };

  const saveResizeSettings = (
    keybinding: string,
    windowSizePercentages: WindowSizePercentage[],
  ) => {
    window.electron.ipcRenderer.invoke('save-resize-settings', {
      keybinding,
      windowSizePercentages,
    });
    dispatch({
      type: 'SAVE_RESIZE_SETTINGS',
      payload: { keybinding, windowSizePercentages },
    });
  };

  const resetSettings = () => {
    window.electron.ipcRenderer.invoke('reset-settings');
    dispatch({ type: 'RESET_SETTINGS' });
  };

  const contextValue = useMemo(
    () => ({
      ...state,
      settings: state,
      saveCenterSettings,
      saveResizeSettings,
      resetSettings,
    }),
    [state],
  );

  return (
    <SettingsContext.Provider value={contextValue}>
      {children}
    </SettingsContext.Provider>
  );
}

export default SettingsProvider;
