import { useState } from 'react';
import useKeybindHandler from '@/renderer/hooks/useKeybindHandler';
import {
  WindowSizePercentage,
  useSettingsContext,
} from '@/renderer/providers/SettingsProvider';
import './ResizeTabContent.css';

function ResizeTabContent() {
  const { settings, saveResizeSettings } = useSettingsContext();

  const [presets, setPresets] = useState<WindowSizePercentage[]>(
    settings.resizeWindow.windowSizePercentages,
  );

  const {
    inputRef,
    keybind,
    handleKeyDown,
    handleSubmit,
    handleFocus,
    handleBlur,
  } = useKeybindHandler(settings.resizeWindow.keybinding, (newKeybind) =>
    saveResizeSettings(newKeybind, presets),
  );

  const handlePresetChange = (
    index: number,
    field: 'width' | 'height',
    value: string,
  ) => {
    const updatedPresets = [...presets];
    updatedPresets[index][field] = value;
    setPresets(updatedPresets);
  };

  const addPreset = () => {
    setPresets([...presets, { width: '50', height: '50' }]);
  };

  const removePreset = (index: number) => {
    const updatedPresets = [...presets];
    updatedPresets.splice(index, 1); // Remove the preset at the specified index
    setPresets(updatedPresets);
  };

  return (
    <div id="resize" className="tabcontent">
      <h3>Resize Window</h3>
      <form onSubmit={handleSubmit}>
        <div className="resize-content">
          <label className="keybind-label" htmlFor="resizeKeybind">
            Keybind:
            <input
              ref={inputRef}
              type="text"
              className="keybinding-input"
              id="resizeKeybind"
              placeholder="Enter Shortcut (e.g., F9)"
              value={keybind}
              onFocus={handleFocus}
              onBlur={handleBlur}
              onKeyDown={handleKeyDown}
              readOnly
            />
            <span className="input-help">Press Esc to reset</span>
          </label>

          {presets.map((preset, index) => (
            <div key={`preset-${index.toString()}`}>
              <div className="display-flex justify-between align-center">
                <h4>Preset {index + 1}</h4>
                <button
                  type="button"
                  className="delete-preset-button"
                  onClick={() => removePreset(index)}
                  aria-label={`Delete preset ${index + 1}`}
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="24"
                    height="24"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <path d="M3 6h18" />
                    <path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6" />
                    <path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2" />
                    <line x1="10" x2="10" y1="11" y2="17" />
                    <line x1="14" x2="14" y1="11" y2="17" />
                  </svg>
                </button>
              </div>
              <div className="dimensions">
                <label htmlFor={`width-${index}`}>
                  <p className="dimensions-label">Width:</p>
                  <input
                    type="range"
                    id={`width-${index}`}
                    min="1"
                    max="100"
                    value={preset.width}
                    onChange={(e) =>
                      handlePresetChange(index, 'width', e.target.value)
                    }
                  />
                  <span className="input-value-wrapper">
                    <input
                      type="number"
                      className="range-input-value"
                      id={`width-value-${index}`}
                      min="1"
                      max="100"
                      value={preset.width}
                      onChange={(e) =>
                        handlePresetChange(index, 'width', e.target.value)
                      }
                    />
                    %
                  </span>
                </label>

                <label htmlFor={`height-${index}`}>
                  <p className="dimensions-label">Height:</p>
                  <input
                    type="range"
                    id={`height-${index}`}
                    min="1"
                    max="100"
                    value={preset.height}
                    onChange={(e) =>
                      handlePresetChange(index, 'height', e.target.value)
                    }
                  />
                  <span className="input-value-wrapper">
                    <input
                      type="number"
                      className="range-input-value"
                      id={`height-value-${index}`}
                      min="1"
                      max="100"
                      value={preset.height}
                      onChange={(e) =>
                        handlePresetChange(index, 'height', e.target.value)
                      }
                    />
                    %
                  </span>
                </label>
              </div>
              {index !== presets.length - 1 && <hr />}
            </div>
          ))}

          <button type="button" onClick={addPreset} className="mt-4">
            Add Preset
          </button>
          <button className="save-button" type="submit">
            Save
          </button>
        </div>
      </form>
    </div>
  );
}

export default ResizeTabContent;
