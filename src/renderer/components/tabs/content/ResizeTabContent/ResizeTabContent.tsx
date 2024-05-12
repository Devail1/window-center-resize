import { FormEvent } from 'react';
import './ResizeTabContent.css';

function ResizeTabContent() {
  const saveResizeSettings = (event: FormEvent) => {
    event.preventDefault();
    // Implement your logic to save resize settings
  };

  return (
    <div id="resize" className="tabcontent">
      <h3>Resize Window</h3>
      <form onSubmit={saveResizeSettings}>
        <div className="display-flex">
          <label className="keybind-label" htmlFor="resizeKeybind">
            Keybind:
            <input
              type="text"
              className="keybinding-input"
              id="resizeKeybind"
              placeholder="Enter Shortcut (e.g., F9)"
            />
          </label>

          <span className="input-help">Press Esc to reset</span>
        </div>
        <div>
          <h4>Small Size</h4>
          <label htmlFor="smallWidthPercentage">
            <p className="dimensions-label">Width:</p>
            <input
              type="range"
              id="smallWidthPercentage"
              min="1"
              max="100"
              value="50"
            />

            <span className="input-value-wrapper">
              <input
                type="number"
                className="range-input-value"
                id="smallWidthPercentage-value"
                min="1"
                max="100"
                value="50"
              />
              %
            </span>
          </label>
          <br />
          <label htmlFor="smallHeightPercentage">
            <p className="dimensions-label">Height:</p>
            <input
              type="range"
              id="smallHeightPercentage"
              min="1"
              max="100"
              value="50"
            />
          </label>

          <span className="input-value-wrapper">
            <input
              type="number"
              className="range-input-value"
              id="smallHeightPercentage-value"
              min="1"
              max="100"
              value="50"
            />
            %
          </span>
        </div>
        {/* Medium and Large Size content */}
        <button className="save-button" type="submit">
          Save
        </button>
      </form>
    </div>
  );
}

export default ResizeTabContent;
