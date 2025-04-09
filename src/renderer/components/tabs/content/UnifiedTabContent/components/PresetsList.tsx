import React from 'react';
import './PresetsList.css';

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

  const formatPosition = (x: number, y: number) => {
    const xPercent = (x / screenSize.width) * 100;
    const yPercent = (y / screenSize.height) * 100;
    return `L:${xPercent.toFixed(0)}% T:${yPercent.toFixed(0)}%`;
  };

  const widthPercent = preset.width / screenSize.width;
  const heightPercent = preset.height / screenSize.height;

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
      <div className="preset-content">
        <div className="preset-header">
          <span className="preset-title">
            {id}
            {isEditing && activePreset === id && (
              <span className="editing-badge">Editing</span>
            )}
          </span>
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
        <div className="preset-details">
          <div className="preset-size">
            <span title="Width × Height">
              <span className="preset-label">Size:</span>{' '}
              {formatNumber(widthPercent, true)} ×{' '}
              {formatNumber(heightPercent, true)}
            </span>
          </div>
          <div className="preset-position">
            <span title="Position from Left and Top edges">
              <span className="preset-label">Pos:</span>{' '}
              {formatPosition(preset.x, preset.y)}
            </span>
          </div>
        </div>
      </div>
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
