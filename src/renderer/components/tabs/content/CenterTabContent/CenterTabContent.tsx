import { useSettingsContext } from '@/renderer/providers/SettingsProvider';
import useKeybindHandler from '@/renderer/hooks/useKeybindHandler';
import './CenterTabContent.css';

function CenterTabContent() {
  const { settings, saveCenterSettings } = useSettingsContext();

  const {
    inputRef,
    keybind,
    handleKeyDown,
    handleSubmit,
    handleFocus,
    handleBlur,
  } = useKeybindHandler(settings.centerWindow.keybinding, saveCenterSettings);

  return (
    <div id="center" className="tabcontent active">
      <h3>Center Window</h3>
      <form onSubmit={handleSubmit}>
        <div className="display-flex">
          <label className="keybind-label" htmlFor="centerKeybind">
            Keybind:
            <input
              ref={inputRef}
              type="text"
              className="keybinding-input"
              id="centerKeybind"
              placeholder="Enter Shortcut (e.g., Win+Shift+C)"
              value={keybind}
              onFocus={handleFocus}
              onBlur={handleBlur}
              onKeyDown={handleKeyDown}
              readOnly
            />
            <span className="input-help">Press Esc to reset</span>
          </label>
        </div>

        <button className="save-button" type="submit">
          Save
        </button>
      </form>
    </div>
  );
}

export default CenterTabContent;
