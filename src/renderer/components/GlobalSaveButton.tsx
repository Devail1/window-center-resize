import React, { useState } from 'react';
import { useSettingsContext } from '@/renderer/providers/SettingsProvider';
import './GlobalSaveButton.css';

function GlobalSaveButton(): React.ReactElement {
  const { settings, saveCenterSettings, saveResizeSettings } =
    useSettingsContext();
  const [isSaving, setIsSaving] = useState(false);

  const handleSave = () => {
    setIsSaving(true);

    // Save all settings
    saveCenterSettings(settings.centerWindow.keybinding);
    saveResizeSettings(
      settings.resizeWindow.keybinding,
      settings.resizeWindow.windowSizePercentages,
    );

    // Reset saving state after a delay
    setTimeout(() => setIsSaving(false), 1000);
  };

  return (
    <button
      type="button"
      className={`global-save-button ${isSaving ? 'saving' : ''}`}
      onClick={handleSave}
      disabled={isSaving}
    >
      {isSaving ? 'Saving...' : 'Save All Settings'}
    </button>
  );
}

export default GlobalSaveButton;
