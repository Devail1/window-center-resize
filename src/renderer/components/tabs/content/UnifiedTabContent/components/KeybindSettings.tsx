import React, { useEffect, useCallback } from 'react';
import useKeybindHandler from '@/renderer/hooks/useKeybindHandler';
import { useSettingsContext } from '@/renderer/providers/SettingsProvider';

function KeybindSettings(): React.ReactElement {
  const { settings, saveCenterSettings, saveResizeSettings } =
    useSettingsContext();

  const handleCenterSave = useCallback(
    (keybind: string) => {
      saveCenterSettings(keybind);
    },
    [saveCenterSettings],
  );

  const handleResizeSave = useCallback(
    (keybind: string) => {
      saveResizeSettings(keybind, settings.resizeWindow.windowSizePercentages);
    },
    [saveResizeSettings, settings.resizeWindow.windowSizePercentages],
  );

  const {
    inputRef: centerInputRef,
    keybind: centerKeybind,
    handleKeyDown: handleCenterKeyDown,
    handleFocus: handleCenterFocus,
    handleBlur: handleCenterBlur,
  } = useKeybindHandler(
    settings.centerWindow?.keybinding || '',
    handleCenterSave,
  );

  const {
    inputRef: resizeInputRef,
    keybind: resizeKeybind,
    handleKeyDown: handleResizeKeyDown,
    handleFocus: handleResizeFocus,
    handleBlur: handleResizeBlur,
  } = useKeybindHandler(
    settings.resizeWindow?.keybinding || '',
    handleResizeSave,
  );

  // Only update inputs when settings change and inputs are not focused
  useEffect(() => {
    if (centerInputRef.current && !centerInputRef.current.matches(':focus')) {
      centerInputRef.current.value = settings.centerWindow?.keybinding || '';
    }
    if (resizeInputRef.current && !resizeInputRef.current.matches(':focus')) {
      resizeInputRef.current.value = settings.resizeWindow?.keybinding || '';
    }
  }, [settings, centerInputRef, resizeInputRef]);

  return (
    <div className="keybind-section">
      <div className="keybind-group">
        <h3>Center Window</h3>
        <form
          onSubmit={(e) => {
            e.preventDefault();
            if (centerKeybind) {
              handleCenterSave(centerKeybind);
            }
          }}
        >
          <label className="keybind-label" htmlFor="centerKeybind">
            Keybind:
            <input
              ref={centerInputRef}
              type="text"
              className="keybinding-input"
              id="centerKeybind"
              placeholder="Enter Shortcut (e.g., Win+Shift+C)"
              defaultValue={settings.centerWindow?.keybinding || ''}
              onFocus={handleCenterFocus}
              onBlur={handleCenterBlur}
              onKeyDown={handleCenterKeyDown}
              readOnly
            />
            <span className="input-help">Press Esc to reset</span>
          </label>
        </form>
      </div>

      <div className="keybind-group">
        <h3>Resize Window</h3>
        <form
          onSubmit={(e) => {
            e.preventDefault();
            if (resizeKeybind) {
              handleResizeSave(resizeKeybind);
            }
          }}
        >
          <label className="keybind-label" htmlFor="resizeKeybinding">
            Keybind:
            <input
              ref={resizeInputRef}
              type="text"
              className="keybinding-input"
              id="resizeKeybinding"
              placeholder="Enter Shortcut (e.g., F9)"
              defaultValue={settings.resizeWindow?.keybinding || ''}
              onFocus={handleResizeFocus}
              onBlur={handleResizeBlur}
              onKeyDown={handleResizeKeyDown}
              readOnly
            />
            <span className="input-help">Press Esc to reset</span>
          </label>
        </form>
      </div>
    </div>
  );
}

export default KeybindSettings;
