import React, { useRef } from 'react';
import './TabsList.css';
import { useTabsContext } from '@/renderer/providers/TabsProvider';
import { TTabAction } from '@/renderer/components/AppContainer/AppContainer';
import { useSettingsContext } from '@/renderer/providers/SettingsProvider';

function TabsList() {
  const { resetSettings } = useSettingsContext();
  const { activeTab, setActiveTab } = useTabsContext();
  const dialogRef = useRef<HTMLDialogElement | null>(null);

  const handleClick = (tabName: TTabAction) => {
    setActiveTab(tabName);
  };

  const handleReset = () => {
    if (dialogRef.current) {
      dialogRef.current.showModal(); // Show the dialog when reset is clicked
    }
  };

  const handleConfirm = () => {
    resetSettings();
    if (dialogRef.current) {
      dialogRef.current.close(); // Close the dialog after confirmation
    }
  };

  const handleCancel = () => {
    if (dialogRef.current) {
      dialogRef.current.close(); // Close the dialog if canceled
    }
  };

  return (
    <div className="nav">
      <div className="tab">
        <button
          type="button"
          className={`${activeTab === 'center' && 'active'}`}
          onClick={() => handleClick('center')}
        >
          Center Window
        </button>
        <button
          type="button"
          className={`${activeTab === 'resize' && 'active'}`}
          onClick={() => handleClick('resize')}
        >
          Resize Window
        </button>
      </div>
      <button id="reset-button" type="button" onClick={handleReset}>
        Reset
      </button>

      <dialog ref={dialogRef} className="custom-dialog">
        <div className="custom-dialog-header">
          <h3>Confirm Reset</h3>
        </div>
        <div className="custom-dialog-body">
          <p>
            Are you sure you want to reset your settings? <br /> This action
            cannot be undone.
          </p>
        </div>
        <div className="dialog-buttons">
          <button type="button" onClick={handleConfirm}>
            Confirm
          </button>
          <button type="button" onClick={handleCancel}>
            Cancel
          </button>
        </div>
      </dialog>
    </div>
  );
}

export default TabsList;
