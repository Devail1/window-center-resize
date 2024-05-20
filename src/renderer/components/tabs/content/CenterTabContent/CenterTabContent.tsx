import { FormEvent, useState } from 'react';
import './CenterTabContent.css';
import { useSettingsContext } from '../../../../providers/SettingsProvider';

function CenterTabContent() {
  const { saveCenterSettings } = useSettingsContext();
  const [centerKeybind, setCenterKeybind] = useState<string>('');

  const handleSubmit = (event: FormEvent) => {
    event.preventDefault();
    saveCenterSettings(centerKeybind);
  };

  return (
    <div id="center" className="tabcontent active">
      <h3>Center Window</h3>
      <form onSubmit={handleSubmit}>
        <div className="display-flex">
          <label className="keybind-label" htmlFor="centerKeybind">
            Keybind:
            <input
              type="text"
              className="keybinding-input"
              id="centerKeybind"
              placeholder="Enter Shortcut (e.g., Win+Shift+C)"
              value={centerKeybind}
              onChange={(e) => setCenterKeybind(e.target.value)}
            />
          </label>
          <span className="input-help">Press Esc to reset</span>
        </div>
        <button className="save-button" type="submit">
          Save
        </button>
      </form>
    </div>
  );
}

export default CenterTabContent;
