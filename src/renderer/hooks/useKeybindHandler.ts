import {
  useCallback,
  useEffect,
  useRef,
  useState,
  KeyboardEvent,
  FormEvent,
} from 'react';
import { useRecordHotkeys } from 'react-hotkeys-hook';
import { capitalizeFirstLetterOfEachWord } from '@/renderer/utils';

export default function useKeybindHandler(
  initialKeybind: string,
  onSave: (keybind: string) => void,
) {
  const inputRef = useRef<null | HTMLInputElement>(null);
  const [keybind, setKeybind] = useState<string>(
    capitalizeFirstLetterOfEachWord(initialKeybind),
  );

  const [keys, { start, stop, resetKeys, isRecording }] = useRecordHotkeys();

  const filterUnwantedKeys = (keysList: string[]) =>
    keysList.filter((s) => s !== 'escape' && s !== 'backspace');

  const updateInputRef = useCallback(() => {
    const recordedKeys = filterUnwantedKeys(Array.from(keys)).join(' + ');
    const formattedString = capitalizeFirstLetterOfEachWord(
      recordedKeys.toString(),
    );
    if (keys.size && inputRef?.current && formattedString) {
      inputRef.current.value = formattedString;
      setKeybind(formattedString);
    }
  }, [keys]);

  // Required for immidiate ui updates in the input
  useEffect(() => {
    updateInputRef();
  }, [updateInputRef]);

  const handleKeyDown = useCallback(
    (e: KeyboardEvent<HTMLInputElement>) => {
      const filteredKeys = filterUnwantedKeys(Array.from(keys));
      const lastKeyInput = e.key;

      switch (lastKeyInput) {
        case 'Escape':
          setKeybind('');
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
    onSave(keybind);
    stop();
  };

  const handleFocus = () => {
    if (!isRecording || !keys.size) start();
  };

  const handleBlur = () => {
    if (isRecording) stop();
  };

  return {
    inputRef,
    keybind,
    handleKeyDown,
    handleSubmit,
    handleFocus,
    handleBlur,
  };
}
