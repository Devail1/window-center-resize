import React, {
  createContext,
  useContext,
  useReducer,
  useEffect,
  useMemo,
  ReactNode,
} from 'react';

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
  saveCenterSettings: (centerKeybind: string) => void;
  saveResizeSettings: (
    resizeKeybind: string,
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
        resizeKeybind: string;
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
          keybinding: action.payload.resizeKeybind,
          windowSizePercentages: action.payload.windowSizePercentages,
        },
      };
    case 'RESET_SETTINGS':
      return {
        centerWindow: { keybinding: '' },
        resizeWindow: { keybinding: '', windowSizePercentages: [] },
      };
    default:
      return state;
  }
}

function SettingsProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(settingsReducer, {
    centerWindow: { keybinding: '' },
    resizeWindow: { keybinding: '', windowSizePercentages: [] },
  });

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
    window.electron.ipcRenderer.invoke('save-center-settings', {
      centerWindowKeybinding: centerKeybind,
    });
    dispatch({ type: 'SAVE_CENTER_SETTINGS', payload: { centerKeybind } });
  };

  const saveResizeSettings = (
    resizeKeybind: string,
    windowSizePercentages: WindowSizePercentage[],
  ) => {
    window.electron.ipcRenderer.invoke('save-resize-settings', {
      resizeWindowKeybinding: resizeKeybind,
      resizeWindowPercentages: windowSizePercentages,
    });
    dispatch({
      type: 'SAVE_RESIZE_SETTINGS',
      payload: { resizeKeybind, windowSizePercentages },
    });
  };

  const resetSettings = () => {
    window.electron.ipcRenderer.invoke('reset-settings');
    dispatch({ type: 'RESET_SETTINGS' });
  };

  const contextValue = useMemo(
    () => ({
      ...state,
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