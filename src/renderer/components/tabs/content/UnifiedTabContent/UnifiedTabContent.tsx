import React, { useState, useEffect, useRef, useCallback } from 'react';
import { useSettingsContext } from '@/renderer/providers/SettingsProvider';
import KeybindSettings from './components/KeybindSettings';
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
  const { settings, saveResizeSettings } = useSettingsContext();
  const [position, setPosition] = useState<Position>({
    x: 0,
    y: 0,
    width: window.innerWidth,
    height: window.innerHeight / 2,
  });
  const [presets, setPresets] = useState<Presets>({});
  const [activePreset, setActivePreset] = useState<string | null>(null);
  const [isEditing, setIsEditing] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);
  const initializedRef = useRef(false);
  const [screenSize, setScreenSize] = useState({ width: 1920, height: 1080 });

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

  const handleSavePreset = useCallback(
    (newPosition: Position) => {
      // Convert position to percentages, accounting for window size
      const newPreset = {
        width: (newPosition.width / screenSize.width) * 100,
        height: (newPosition.height / screenSize.height) * 100,
        // Convert x position to percentage relative to available space
        x: (newPosition.x / (screenSize.width - newPosition.width)) * 100,
        // Convert y position to percentage relative to available space
        y: (newPosition.y / (screenSize.height - newPosition.height)) * 100,
      };

      if (isEditing && activePreset) {
        // Update existing preset
        setPresets((currentPresets) => ({
          ...currentPresets,
          [activePreset]: {
            ...newPosition,
            width: Math.round(newPosition.width),
            height: Math.round(newPosition.height),
            x: Math.round(newPosition.x),
            y: Math.round(newPosition.y),
          },
        }));

        // Update settings by replacing the existing preset
        const presetIndex = parseInt(activePreset.split(' ')[1], 10) - 1;
        const updatedPercentages = [
          ...settings.resizeWindow.windowSizePercentages,
        ];
        updatedPercentages[presetIndex] = newPreset;
        saveResizeSettings(
          settings.resizeWindow.keybinding,
          updatedPercentages,
        );

        // Exit editing mode
        setIsEditing(false);
      } else {
        // Create new preset
        const timestamp = new Date().toLocaleTimeString();
        const newPresetId = `Preset ${timestamp}`;

        // Update local state
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

        // Update settings with new window size percentages
        const currentPercentages =
          settings.resizeWindow.windowSizePercentages || [];
        const updatedPercentages = [...currentPercentages, newPreset];
        saveResizeSettings(
          settings.resizeWindow.keybinding,
          updatedPercentages,
        );
      }
    },
    [screenSize, settings, saveResizeSettings, isEditing, activePreset],
  );

  const handleDeletePreset = useCallback(
    (presetId: string) => {
      // Don't allow deleting if there's only one preset
      if (Object.keys(presets).length <= 1) {
        return;
      }

      setPresets((currentPresets) => {
        const newPresets = { ...currentPresets };
        delete newPresets[presetId];
        return newPresets;
      });

      // Update settings by removing the corresponding window size percentage
      const presetIndex = parseInt(presetId.split(' ')[1], 10) - 1;
      const updatedPercentages =
        settings.resizeWindow.windowSizePercentages.filter(
          (_, index) => index !== presetIndex,
        );
      saveResizeSettings(settings.resizeWindow.keybinding, updatedPercentages);
    },
    [settings, saveResizeSettings, presets],
  );

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

  // Update presets whenever settings change
  useEffect(() => {
    if (
      screenSize.width &&
      screenSize.height &&
      settings.resizeWindow?.windowSizePercentages
    ) {
      const updatedPresets: Presets = {};
      settings.resizeWindow.windowSizePercentages.forEach((preset, index) => {
        const width = (preset.width / 100) * screenSize.width;
        const height = (preset.height / 100) * screenSize.height;
        updatedPresets[`Preset ${index + 1}`] = {
          width: Math.round(width),
          height: Math.round(height),
          // Calculate x position to maintain the window's relative position from the left edge
          x: Math.round((preset.x / 100) * (screenSize.width - width)),
          // Calculate y position to maintain the window's relative position from the top edge
          y: Math.round((preset.y / 100) * (screenSize.height - height)),
        };
      });
      setPresets(updatedPresets);

      // If no active preset is selected, set the first preset as the current position
      if (!activePreset && Object.keys(updatedPresets).length > 0) {
        const firstPresetId = Object.keys(updatedPresets)[0];
        setPosition(updatedPresets[firstPresetId]);
      }
    }
  }, [screenSize, settings.resizeWindow?.windowSizePercentages, activePreset]);

  // Only initialize presets once when settings are loaded
  useEffect(() => {
    if (
      !initializedRef.current &&
      screenSize.width &&
      screenSize.height &&
      settings.resizeWindow?.windowSizePercentages
    ) {
      // Skip initialization if there are no presets in settings
      if (settings.resizeWindow.windowSizePercentages.length > 0) {
        const defaultPresets: Presets = {};
        settings.resizeWindow.windowSizePercentages.forEach((preset, index) => {
          const width = (preset.width / 100) * screenSize.width;
          const height = (preset.height / 100) * screenSize.height;
          defaultPresets[`Preset ${index + 1}`] = {
            width: Math.round(width),
            height: Math.round(height),
            // Calculate x position to maintain the window's relative position from the left edge
            x: Math.round((preset.x / 100) * (screenSize.width - width)),
            // Calculate y position to maintain the window's relative position from the top edge
            y: Math.round((preset.y / 100) * (screenSize.height - height)),
          };
        });
        setPresets(defaultPresets);

        // Set the first preset as the initial position
        if (Object.keys(defaultPresets).length > 0) {
          const firstPresetId = Object.keys(defaultPresets)[0];
          setPosition(defaultPresets[firstPresetId]);
        }
      }
      initializedRef.current = true;
    }
  }, [screenSize, settings.resizeWindow?.windowSizePercentages]);

  return (
    <div className="unified-tab-content">
      <div className="controls-section">
        <KeybindSettings />
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
        />
        <button
          type="button"
          className="save-preset-button"
          onClick={() => handleSavePreset(position)}
        >
          {isEditing ? 'Update Current Preset' : 'Save as New Preset'}
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
