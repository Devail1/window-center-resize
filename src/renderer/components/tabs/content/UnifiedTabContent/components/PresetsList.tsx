import React from 'react';

interface Preset {
  x: number;
  y: number;
  width: number;
  height: number;
}

interface PresetsListProps {
  presets: { [key: string]: Preset };
  activePreset: string | null;
  isEditing: boolean;
  screenSize: { width: number; height: number };
  onPresetClick: (presetId: string) => void;
  onDeletePreset: (presetId: string, e: React.MouseEvent) => void;
}

function PresetItem({
  id,
  preset,
  activePreset,
  isEditing,
  screenSize,
  onPresetClick,
  onDeletePreset,
  allPresets,
}: {
  id: string;
  preset: Preset;
  activePreset: string | null;
  isEditing: boolean;
  screenSize: { width: number; height: number };
  onPresetClick: (presetId: string) => void;
  onDeletePreset: (presetId: string, e: React.MouseEvent) => void;
  allPresets: { [key: string]: Preset };
}): React.ReactElement {
  const formatNumber = (num: number, isPercentage = false) => {
    if (isPercentage) {
      return `${(num * 100).toFixed(2)}%`;
    }
    return `${Math.round(num)}px`;
  };

  return (
    <div
      className={`preset-item ${activePreset === id ? 'active' : ''} ${
        isEditing && activePreset === id ? 'editing' : ''
      }`}
      onClick={() => onPresetClick(id)}
      role="button"
      tabIndex={0}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          onPresetClick(id);
        }
      }}
    >
      <div className="preset-info">
        <span>{id}</span>
        <span>
          {formatNumber(preset.width / screenSize.width, true)} x{' '}
          {formatNumber(preset.height / screenSize.height, true)}
        </span>
      </div>
      {id !== 'Default 50%' && Object.keys(allPresets).length > 1 && (
        <button
          type="button"
          className="delete-preset-button"
          onClick={(e) => onDeletePreset(id, e)}
          title="Delete preset"
        >
          ×
        </button>
      )}
    </div>
  );
}

function PresetsList({
  presets,
  activePreset,
  isEditing,
  screenSize,
  onPresetClick,
  onDeletePreset,
}: PresetsListProps): React.ReactElement {
  return (
    <div className="presets-list">
      {Object.entries(presets).map(([id, preset]) => (
        <PresetItem
          key={id}
          id={id}
          preset={preset}
          activePreset={activePreset}
          isEditing={isEditing}
          screenSize={screenSize}
          onPresetClick={onPresetClick}
          onDeletePreset={onDeletePreset}
          allPresets={presets}
        />
      ))}
    </div>
  );
}

export default PresetsList;
