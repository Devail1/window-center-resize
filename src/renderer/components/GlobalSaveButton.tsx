import React, { useState } from 'react';
import { useSettingsContext } from '@/renderer/providers/SettingsProvider';
import './GlobalSaveButton.css';

function GlobalSaveButton(): React.ReactElement {
  const { saveAllSettings } = useSettingsContext();
  const [isSaving, setIsSaving] = useState(false);

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await saveAllSettings();
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('Error saving settings:', error);
    } finally {
      setTimeout(() => setIsSaving(false), 1000);
    }
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
