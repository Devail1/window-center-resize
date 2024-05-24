import {
  FormEvent,
  KeyboardEvent,
  useCallback,
  useEffect,
  useRef,
  useState,
} from 'react';
import { useRecordHotkeys } from 'react-hotkeys-hook';
import './CenterTabContent.css';
import { useSettingsContext } from '../../../../providers/SettingsProvider';

function CenterTabContent() {
  const inputRef = useRef<null | HTMLInputElement>(null);
  const { settings, saveCenterSettings } = useSettingsContext();

  const [centerKeybind, setCenterKeybind] = useState(
    settings.centerWindow.keybinding,
  );

  const [keys, { start, stop, resetKeys, isRecording }] = useRecordHotkeys();

  const filterUnwantedKeys = (keysList: string[]) =>
    keysList.filter((s) => s !== 'escape' && s !== 'backspace');

  const updateInputRef = useCallback(() => {
    const recordedKeys = filterUnwantedKeys(Array.from(keys)).join(' + ');
    if (keys.size && inputRef?.current) {
      inputRef.current.value = recordedKeys;
      setCenterKeybind(recordedKeys);
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
          setCenterKeybind('');
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
    saveCenterSettings(centerKeybind);
    stop();
  };

  const handleFocus = () => {
    if (!isRecording || !keys.size) start();
  };

  const handleBlur = () => {
    if (isRecording) stop();
  };

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
              value={centerKeybind}
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
