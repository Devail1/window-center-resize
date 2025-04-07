import React, { useState, useEffect, useRef, useCallback } from 'react';
import { useGridSnap } from '@/renderer/hooks/useGridSnap';
import { useSettingsContext } from '@/renderer/providers/SettingsProvider';
import KeybindSettings from './components/KeybindSettings';
import GridControls from './components/GridControls';
import QuickActions from './components/QuickActions';
import ScreenPreview from './components/ScreenPreview';
import PresetsList from './components/PresetsList';
import './UnifiedTabContent.css';

interface Position {
  x: number;
  y: number;
  width: number;
  height: number;
}

interface Preset {
  x: number;
  y: number;
  width: number;
  height: number;
}

interface Presets {
  [key: string]: Preset;
}

function UnifiedTabContent(): React.ReactElement {
  const { settings, resetSettings } = useSettingsContext();
  const [position, setPosition] = useState<Position>({
    x: 0,
    y: 0,
    width: 800,
    height: 600,
  });
  const [presets, setPresets] = useState<Presets>({});
  const [activePreset, setActivePreset] = useState<string | null>(null);
  const [isEditing, setIsEditing] = useState(false);
  const [showGrid, setShowGrid] = useState(false);
  const [snapToGrid, setSnapToGrid] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);
  const [screenSize, setScreenSize] = useState({ width: 1920, height: 1080 });

  const { gridLines } = useGridSnap(containerRef, showGrid);

  useEffect(() => {
    const handleResize = () => {
      setScreenSize({
        width: window.innerWidth,
        height: window.innerHeight,
      });
    };

    handleResize();
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  const handleSavePreset = useCallback((newPosition: Position) => {
    const timestamp = new Date().toLocaleTimeString();
    const newPresetId = `Preset ${timestamp}`;

    setPresets((currentPresets) => ({
      ...currentPresets,
      [newPresetId]: {
        ...newPosition,
        width: Math.round(newPosition.width),
        height: Math.round(newPosition.height),
        x: Math.round(newPosition.x),
        y: Math.round(newPosition.y),
      },
    }));
  }, []);

  const handleDeletePreset = useCallback((presetId: string) => {
    setPresets((currentPresets) => {
      const newPresets = { ...currentPresets };
      delete newPresets[presetId];
      return newPresets;
    });
  }, []);

  const handlePresetClick = useCallback(
    (presetId: string) => {
      if (activePreset === presetId) {
        setIsEditing(true);
      } else {
        setActivePreset(presetId);
        setIsEditing(false);
        if (presets[presetId]) {
          setPosition(presets[presetId]);
        }
      }
    },
    [activePreset, presets],
  );

  const handleQuickAction = useCallback(
    (newPosition: Position) => {
      const boundedPosition = {
        x: Math.max(
          0,
          Math.min(newPosition.x, screenSize.width - newPosition.width),
        ),
        y: Math.max(
          0,
          Math.min(newPosition.y, screenSize.height - newPosition.height),
        ),
        width: Math.min(newPosition.width, screenSize.width),
        height: Math.min(newPosition.height, screenSize.height),
      };
      setPosition(boundedPosition);
    },
    [screenSize],
  );

  const handlePositionChange = useCallback(
    (newPosition: Position) => {
      const boundedPosition = {
        x: Math.max(
          0,
          Math.min(newPosition.x, screenSize.width - newPosition.width),
        ),
        y: Math.max(
          0,
          Math.min(newPosition.y, screenSize.height - newPosition.height),
        ),
        width: Math.min(newPosition.width, screenSize.width),
        height: Math.min(newPosition.height, screenSize.height),
      };
      setPosition(boundedPosition);
    },
    [screenSize],
  );

  // Only initialize presets once when settings are loaded
  useEffect(() => {
    if (
      Object.keys(presets).length === 0 &&
      screenSize.width &&
      screenSize.height &&
      settings.resizeWindow?.windowSizePercentages
    ) {
      const defaultPresets: Presets = {};
      settings.resizeWindow.windowSizePercentages.forEach((preset, index) => {
        defaultPresets[`Preset ${index + 1}`] = {
          width: (preset.width / 100) * screenSize.width,
          height: (preset.height / 100) * screenSize.height,
          x: (screenSize.width - (preset.width / 100) * screenSize.width) / 2,
          y:
            (screenSize.height - (preset.height / 100) * screenSize.height) / 2,
        };
      });
      setPresets(defaultPresets);
    }
  }, [screenSize, settings.resizeWindow?.windowSizePercentages, presets]);

  return (
    <div className="unified-tab-content">
      <div className="controls-section">
        <KeybindSettings onReset={resetSettings} />
        <GridControls
          showGrid={showGrid}
          snapToGrid={snapToGrid}
          onShowGridChange={setShowGrid}
          onSnapToGridChange={setSnapToGrid}
        />
        <QuickActions
          screenSize={screenSize}
          onQuickAction={handleQuickAction}
        />
      </div>
      <div className="preview-section" ref={containerRef}>
        <ScreenPreview
          position={position}
          screenSize={screenSize}
          onPositionChange={handlePositionChange}
          showGrid={showGrid}
          snapToGrid={snapToGrid}
        />
        {showGrid && gridLines}
        <button
          type="button"
          className="save-preset-button"
          onClick={() => handleSavePreset(position)}
        >
          Save Current Position
        </button>
      </div>
      <div className="presets-section">
        <PresetsList
          presets={presets}
          activePreset={activePreset}
          isEditing={isEditing}
          screenSize={screenSize}
          onPresetClick={handlePresetClick}
          onDeletePreset={handleDeletePreset}
        />
      </div>
    </div>
  );
}

export default UnifiedTabContent;
