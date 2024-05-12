import { FormEvent } from 'react';
import './CenterTabContent.css';

function CenterTabContent() {
  const saveCenterSettings = (event: FormEvent) => {
    event.preventDefault();
    // Implement your logic to save center settings
  };

  return (
    <div id="center" className="tabcontent active">
      <h3>Center Window</h3>
      <form onSubmit={saveCenterSettings}>
        <div className="display-flex">
          <label className="keybind-label" htmlFor="centerKeybind">
            Keybind:
            <input
              type="text"
              className="keybinding-input"
              id="centerKeybind"
              placeholder="Enter Shortcut (e.g., Win+Shift+C)"
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
