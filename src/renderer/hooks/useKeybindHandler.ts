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
  const [keybind, setKeybind] = useState<string>(initialKeybind);
  const [isEditing, setIsEditing] = useState(false);
  const [isDirty, setIsDirty] = useState(false);

  const [keys, { start, stop, resetKeys, isRecording }] = useRecordHotkeys();

  const filterUnwantedKeys = (keysList: string[]) =>
    keysList.filter((s) => s !== 'escape' && s !== 'backspace');

  const updateInputRef = useCallback(() => {
    const recordedKeys = filterUnwantedKeys(Array.from(keys));
    const formattedString = capitalizeFirstLetterOfEachWord(
      recordedKeys.join(' + '),
    );
    if (keys.size && inputRef?.current) {
      inputRef.current.value = formattedString;
      setKeybind(formattedString);
      setIsDirty(true);
    }
  }, [keys]);

  // Update input value when keys change
  useEffect(() => {
    if (isRecording && isEditing) {
      updateInputRef();
    }
  }, [keys, isRecording, updateInputRef, isEditing]);

  const handleKeyDown = useCallback(
    (e: KeyboardEvent<HTMLInputElement>) => {
      const filteredKeys = filterUnwantedKeys(Array.from(keys));
      const lastKeyInput = e.key;

      switch (lastKeyInput) {
        case 'Escape':
          if (inputRef.current) {
            inputRef.current.value = initialKeybind;
          }
          setKeybind(initialKeybind);
          resetKeys();
          setIsEditing(false);
          setIsDirty(false);
          break;

        case 'Backspace':
          if (filteredKeys.length) {
            filteredKeys.pop();
            keys.clear();
            filteredKeys.forEach((key) => keys.add(key));
            updateInputRef();
          }
          break;

        default:
          break;
      }
    },
    [keys, updateInputRef, resetKeys, initialKeybind],
  );

  const handleSubmit = (event: FormEvent) => {
    event.preventDefault();
    if (keybind && isDirty) {
      onSave(keybind);
    }
    stop();
    setIsEditing(false);
    setIsDirty(false);
  };

  const handleFocus = () => {
    if (!isRecording) {
      start();
      setIsEditing(true);
    }
  };

  const handleBlur = () => {
    if (isRecording) {
      stop();
      setIsEditing(false);
      // If no keys were recorded or not dirty, restore the previous value
      if ((!keys.size || !isDirty) && inputRef.current) {
        inputRef.current.value = keybind;
      } else if (isDirty) {
        // If we have changes, save them
        onSave(keybind);
      }
    }
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
