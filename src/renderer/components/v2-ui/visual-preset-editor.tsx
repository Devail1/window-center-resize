'use client';

import React, { useState, useRef, useEffect } from 'react';
import { Play, Save, X, Power, PowerOff, Monitor } from 'lucide-react';
import useKeybindHandler from '@/renderer/hooks/useKeybindHandler';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '../ui/card';
import { Separator } from '../ui/separator';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '../ui/select';

interface Preset {
  id: string;
  name: string;
  x: number;
  y: number;
  width: number;
  height: number;
  shortcut: string;
  unit: 'px' | '%';
  enabled: boolean;
}

interface VisualPresetEditorProps {
  preset: Preset | null;
  onSave: (preset: Preset) => void;
  onCancel: () => void;
}

export function VisualPresetEditor({
  preset,
  onSave,
  onCancel,
}: VisualPresetEditorProps) {
  const [editingPreset, setEditingPreset] = useState<Preset | null>(preset);
  const [isDragging, setIsDragging] = useState(false);
  const [isResizing, setIsResizing] = useState(false);
  const canvasRef = useRef<HTMLDivElement>(null);
  const [screenSize, setScreenSize] = useState({ width: 1920, height: 1080 });

  // Use the same keybind handler as the legacy code
  const {
    inputRef: shortcutInputRef,
    keybind: shortcutKeybind,
    handleKeyDown: handleShortcutKeyDown,
    handleFocus: handleShortcutFocus,
    handleBlur: handleShortcutBlur,
  } = useKeybindHandler(
    editingPreset?.shortcut || '',
    (newShortcut: string) => {
      if (editingPreset) {
        setEditingPreset({ ...editingPreset, shortcut: newShortcut });
      }
    },
  );

  useEffect(() => {
    setEditingPreset(preset);
  }, [preset]);

  // Get actual screen size for correct aspect ratio
  useEffect(() => {
    const getScreenSize = async () => {
      try {
        if (window.electronAPI?.getScreenSize) {
          const size = await window.electronAPI.getScreenSize();
          setScreenSize(size);
        }
      } catch (error) {
        // Fallback to default size
        setScreenSize({ width: 1920, height: 1080 });
      }
    };
    getScreenSize();
  }, []);

  if (!editingPreset) {
    return (
      <Card className="h-96 flex items-center justify-center">
        <div className="text-center space-y-4">
          <Monitor className="h-12 w-12 mx-auto text-muted-foreground" />
          <div>
            <h3 className="text-lg font-medium">No Preset Selected</h3>
            <p className="text-sm text-muted-foreground">
              Select a preset from the list or create a new one to start editing
            </p>
          </div>
        </div>
      </Card>
    );
  }

  const handleMouseDown = (e: React.MouseEvent, action: 'drag' | 'resize') => {
    e.preventDefault();
    if (action === 'drag') {
      setIsDragging(true);
    } else {
      setIsResizing(true);
    }
  };

  const handleMouseMove = (e: React.MouseEvent) => {
    if (!isDragging && !isResizing) return;

    const rect = canvasRef.current?.getBoundingClientRect();
    if (!rect) return;

    const x = ((e.clientX - rect.left) / rect.width) * 100;
    const y = ((e.clientY - rect.top) / rect.height) * 100;

    if (isDragging) {
      setEditingPreset({
        ...editingPreset,
        x: Math.max(
          0,
          Math.min(100 - editingPreset.width, x - editingPreset.width / 2),
        ),
        y: Math.max(
          0,
          Math.min(100 - editingPreset.height, y - editingPreset.height / 2),
        ),
      });
    } else if (isResizing) {
      const newWidth = Math.max(
        10,
        Math.min(100 - editingPreset.x, x - editingPreset.x),
      );
      const newHeight = Math.max(
        10,
        Math.min(100 - editingPreset.y, y - editingPreset.y),
      );

      setEditingPreset({
        ...editingPreset,
        width: newWidth,
        height: newHeight,
      });
    }
  };

  const handleMouseUp = () => {
    setIsDragging(false);
    setIsResizing(false);
  };

  const handleTestApply = async () => {
    if (!editingPreset) return;

    try {
      if (window.electronAPI?.applyPreset) {
        const result = await window.electronAPI.applyPreset(editingPreset);
        if (result.success) {
          // eslint-disable-next-line no-console
          console.log('Preset applied successfully:', editingPreset.name);
        } else {
          // eslint-disable-next-line no-console
          console.error('Failed to apply preset:', result.error);
        }
      } else {
        // eslint-disable-next-line no-console
        console.log('Applying preset (dev mode):', editingPreset);
      }
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('Error applying preset:', error);
    }
  };

  const handleSave = () => {
    if (!editingPreset) return;

    // Check for conflicts (you might want to check against other presets)
    if (shortcutKeybind) {
      setEditingPreset({
        ...editingPreset,
        shortcut: shortcutKeybind,
      });
    }

    onSave(editingPreset);
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      {/* Visual Editor */}
      <div className="lg:col-span-2">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Monitor className="h-5 w-5" />
              Screen Preview
            </CardTitle>
            <CardDescription>
              Drag the window to position it, resize from the bottom-right
              corner
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div
              ref={canvasRef}
              className="relative w-full bg-muted rounded-lg border-2 border-dashed border-muted-foreground/20 overflow-hidden cursor-crosshair"
              style={{
                aspectRatio: `${screenSize.width} / ${screenSize.height}`,
              }}
              onMouseMove={handleMouseMove}
              onMouseUp={handleMouseUp}
              onMouseLeave={handleMouseUp}
              onKeyDown={(e) => {
                // Add keyboard support for accessibility
                if (e.key === 'Escape') {
                  handleMouseUp();
                }
              }}
              role="presentation"
              aria-label="Visual window preset editor. Use mouse to drag and resize the blue window. Press Escape to cancel current action."
            >
              {/* Screen representation */}
              <div className="absolute inset-2 bg-background rounded border">
                {/* Window representation */}
                <div
                  className="absolute bg-primary/20 border-2 border-primary rounded shadow-lg cursor-move"
                  style={{
                    left: `${editingPreset.x}%`,
                    top: `${editingPreset.y}%`,
                    width: `${editingPreset.width}%`,
                    height: `${editingPreset.height}%`,
                  }}
                  onMouseDown={(e) => handleMouseDown(e, 'drag')}
                  role="button"
                  tabIndex={0}
                  aria-label="Drag to move window preset"
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                      e.preventDefault();
                    }
                  }}
                >
                  {/* Window title bar */}
                  <div className="h-6 bg-primary/40 border-b border-primary/30 rounded-t flex items-center px-2">
                    <div className="flex gap-1">
                      <div className="w-2 h-2 rounded-full bg-red-500/60" />
                      <div className="w-2 h-2 rounded-full bg-yellow-500/60" />
                      <div className="w-2 h-2 rounded-full bg-green-500/60" />
                    </div>
                    <div className="flex-1 text-center">
                      <span className="text-xs text-primary font-medium">
                        {editingPreset.name}
                      </span>
                    </div>
                  </div>

                  {/* Resize handle */}
                  <div
                    className="absolute bottom-0 right-0 w-4 h-4 bg-primary/60 cursor-se-resize"
                    onMouseDown={(e) => {
                      e.stopPropagation();
                      handleMouseDown(e, 'resize');
                    }}
                    role="button"
                    tabIndex={0}
                    aria-label="Drag to resize window preset"
                    onKeyDown={(e) => {
                      if (e.key === 'Enter' || e.key === ' ') {
                        e.preventDefault();
                      }
                    }}
                  >
                    <div className="absolute bottom-1 right-1 w-2 h-2 border-r-2 border-b-2 border-primary" />
                  </div>
                </div>
              </div>

              {/* Coordinates display */}
              <div className="absolute top-2 left-2 bg-background/90 backdrop-blur rounded px-2 py-1 text-xs font-mono">
                X: {Math.round(editingPreset.x)}
                {editingPreset.unit} | Y: {Math.round(editingPreset.y)}
                {editingPreset.unit} | W: {Math.round(editingPreset.width)}
                {editingPreset.unit} | H: {Math.round(editingPreset.height)}
                {editingPreset.unit}
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Properties Panel */}
      <div className="space-y-6">
        <Card>
          <CardHeader>
            <CardTitle>Preset Properties</CardTitle>
            <CardDescription>
              Fine-tune your window preset settings
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="name">Preset Name</Label>
              <Input
                id="name"
                value={editingPreset.name}
                onChange={(e) =>
                  setEditingPreset({ ...editingPreset, name: e.target.value })
                }
                placeholder="Enter preset name"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="shortcut">Keyboard Shortcut</Label>
              <Input
                id="shortcut"
                ref={shortcutInputRef}
                value={shortcutKeybind}
                onKeyDown={handleShortcutKeyDown}
                onFocus={handleShortcutFocus}
                onBlur={handleShortcutBlur}
                className="w-full"
                placeholder="Press keys..."
                readOnly
              />
            </div>

            <div className="flex items-center justify-between">
              <div className="space-y-0.5">
                <Label htmlFor="enable-preset">Enable Preset</Label>
                <p className="text-xs text-muted-foreground">
                  Allow this preset to respond to keyboard shortcuts
                </p>
              </div>
              <Button
                id="enable-preset"
                type="button"
                variant="ghost"
                size="sm"
                onClick={() =>
                  setEditingPreset({
                    ...editingPreset,
                    enabled: !editingPreset.enabled,
                  })
                }
                className={`p-2 rounded-full transition-colors ${
                  editingPreset.enabled
                    ? 'text-green-600 hover:bg-green-100 dark:hover:bg-green-900/20'
                    : 'text-muted-foreground hover:bg-muted'
                }`}
                aria-label={
                  editingPreset.enabled ? 'Disable preset' : 'Enable preset'
                }
              >
                {editingPreset.enabled ? (
                  <Power className="h-4 w-4" />
                ) : (
                  <PowerOff className="h-4 w-4" />
                )}
              </Button>
            </div>

            <div className="space-y-2">
              <Label htmlFor="unit">Unit</Label>
              <Select
                value={editingPreset.unit}
                onValueChange={(value: 'px' | '%') =>
                  setEditingPreset({ ...editingPreset, unit: value })
                }
              >
                <SelectTrigger id="unit">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="%">Percentage (%)</SelectItem>
                  <SelectItem value="px">Pixels (px)</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <Separator />

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="x">X Position</Label>
                <Input
                  id="x"
                  type="number"
                  value={Math.round(editingPreset.x)}
                  onChange={(e) =>
                    setEditingPreset({
                      ...editingPreset,
                      x: Math.max(0, Math.min(100, Number(e.target.value))),
                    })
                  }
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="y">Y Position</Label>
                <Input
                  id="y"
                  type="number"
                  value={Math.round(editingPreset.y)}
                  onChange={(e) =>
                    setEditingPreset({
                      ...editingPreset,
                      y: Math.max(0, Math.min(100, Number(e.target.value))),
                    })
                  }
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="width">Width</Label>
                <Input
                  id="width"
                  type="number"
                  value={Math.round(editingPreset.width)}
                  onChange={(e) =>
                    setEditingPreset({
                      ...editingPreset,
                      width: Math.max(
                        10,
                        Math.min(100, Number(e.target.value)),
                      ),
                    })
                  }
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="height">Height</Label>
                <Input
                  id="height"
                  type="number"
                  value={Math.round(editingPreset.height)}
                  onChange={(e) =>
                    setEditingPreset({
                      ...editingPreset,
                      height: Math.max(
                        10,
                        Math.min(100, Number(e.target.value)),
                      ),
                    })
                  }
                />
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Actions */}
        <div className="flex flex-col gap-2">
          <Button
            type="button"
            onClick={handleTestApply}
            variant="outline"
            className="w-full bg-transparent"
          >
            <Play className="mr-2 h-4 w-4" />
            Test Apply
          </Button>
          <div className="flex gap-2">
            <Button type="button" onClick={handleSave} className="flex-1">
              <Save className="mr-2 h-4 w-4" />
              Save
            </Button>
            <Button
              type="button"
              onClick={onCancel}
              variant="outline"
              className="flex-1 bg-transparent"
            >
              <X className="mr-2 h-4 w-4" />
              Cancel
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}
