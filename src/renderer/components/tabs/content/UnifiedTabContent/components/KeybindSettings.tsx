import React from 'react';
import useKeybindHandler from '@/renderer/hooks/useKeybindHandler';

interface KeybindSettingsProps {
  centerKeybinding: string;
  resizeKeybinding: string;
  onSave: () => void;
  onReset: () => void;
}

function KeybindSettings({
  centerKeybinding,
  resizeKeybinding,
  onSave,
  onReset,
}: KeybindSettingsProps): React.ReactElement {
  const {
    inputRef: centerInputRef,
    keybind: centerKeybind,
    handleKeyDown: handleCenterKeyDown,
    handleFocus: handleCenterFocus,
    handleBlur: handleCenterBlur,
  } = useKeybindHandler(centerKeybinding, onSave);

  const {
    inputRef: resizeInputRef,
    keybind: resizeKeybind,
    handleKeyDown: handleResizeKeyDown,
    handleFocus: handleResizeFocus,
    handleBlur: handleResizeBlur,
  } = useKeybindHandler(resizeKeybinding, onSave);

  return (
    <div className="keybind-section">
      <div className="keybind-group">
        <h3>Center Window</h3>
        <form
          onSubmit={(e) => {
            e.preventDefault();
            onSave();
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
              value={centerKeybind}
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
            onSave();
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
              value={resizeKeybind}
              onFocus={handleResizeFocus}
              onBlur={handleResizeBlur}
              onKeyDown={handleResizeKeyDown}
              readOnly
            />
            <span className="input-help">Press Esc to reset</span>
          </label>
        </form>
      </div>

      <div className="keybind-group">
        <button
          type="button"
          className="reset-settings-button"
          onClick={onReset}
        >
          Reset to Default
        </button>
      </div>
    </div>
  );
}

export default KeybindSettings;
