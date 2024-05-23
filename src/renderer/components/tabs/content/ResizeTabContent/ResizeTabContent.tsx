import {
  FormEvent,
  KeyboardEvent,
  useCallback,
  useEffect,
  useRef,
  useState,
} from 'react';
import { useRecordHotkeys } from 'react-hotkeys-hook';
import './ResizeTabContent.css';
import {
  WindowSizePercentage,
  useSettingsContext,
} from '../../../../providers/SettingsProvider';

function ResizeTabContent() {
  const inputRef = useRef<null | HTMLInputElement>(null);
  const { settings, saveResizeSettings } = useSettingsContext();

  const [resizeKeybind, setResizeKeybind] = useState<string>(
    settings.resizeWindow.keybinding,
  );
  const [presets, setPresets] = useState<WindowSizePercentage[]>([
    { width: '50', height: '50' },
  ]);

  const [keys, { start, stop, resetKeys, isRecording }] = useRecordHotkeys();

  const filterUnwantedKeys = (keysList: string[]) =>
    keysList.filter((s) => s !== 'escape' && s !== 'backspace');

  const updateInputRef = useCallback(() => {
    const recordedKeys = filterUnwantedKeys(Array.from(keys)).join(' + ');
    if (keys.size && inputRef?.current) {
      inputRef.current.value = recordedKeys;
      setResizeKeybind(recordedKeys);
    }
  }, [keys]);

  useEffect(() => {
    updateInputRef();
  }, [updateInputRef]);

  const handleKeyDown = useCallback(
    (e: KeyboardEvent<HTMLInputElement>) => {
      const filteredKeys = filterUnwantedKeys(Array.from(keys));
      const lastKeyInput = e.key;

      switch (lastKeyInput) {
        case 'Escape':
          setResizeKeybind('');
          resetKeys();
          break;

        case 'Backspace':
          if (filteredKeys.length) {
            filteredKeys.pop();
            keys.clear();
            filteredKeys.forEach((key) => keys.add(key));
          }
          break;

        default:
          break;
      }
      updateInputRef();
    },
    [keys, updateInputRef, resetKeys],
  );

  const handleSubmit = (event: FormEvent) => {
    event.preventDefault();
    saveResizeSettings(resizeKeybind, presets);
    stop();
  };

  const handleFocus = () => {
    if (!isRecording || !keys.size) start();
  };

  const handleBlur = () => {
    if (isRecording) stop();
  };

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

  return (
    <div id="resize" className="tabcontent">
      <h3>Resize Window</h3>
      <form onSubmit={handleSubmit}>
        <div className="display-flex">
          <label className="keybind-label" htmlFor="resizeKeybind">
            Keybind:
            <input
              ref={inputRef}
              type="text"
              className="keybinding-input"
              id="resizeKeybind"
              placeholder="Enter Shortcut (e.g., F9)"
              value={resizeKeybind}
              onFocus={handleFocus}
              onBlur={handleBlur}
              onKeyDown={handleKeyDown}
              readOnly
            />
            <span className="input-help">Press Esc to reset</span>
          </label>
        </div>

        {presets.map((preset, index) => (
          <div key={`preset-${index.toString()}`}>
            <h4>Preset {index + 1}</h4>
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
            <br />
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
        ))}

        <button type="button" onClick={addPreset}>
          Add Preset
        </button>
        <button className="save-button" type="submit">
          Save
        </button>
      </form>
    </div>
  );
}

export default ResizeTabContent;
