import React, { useState } from 'react';
import { useSettingsContext } from '@/renderer/providers/SettingsProvider';
import './GlobalActionsSection.css';

function GlobalActionsSection(): React.ReactElement {
  const { saveAllSettings, resetSettings } = useSettingsContext();
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
    <div className="global-actions-section">
      <button
        type="button"
        className={`global-save-button ${isSaving ? 'saving' : ''}`}
        onClick={handleSave}
        disabled={isSaving}
      >
        {isSaving ? 'Saving...' : 'Save All Settings'}
      </button>
      <button
        type="button"
        className="reset-all-settings-button"
        onClick={resetSettings}
      >
        Reset All Settings
      </button>
    </div>
  );
}

export default GlobalActionsSection;
