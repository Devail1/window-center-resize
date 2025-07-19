'use client';

import { Button } from '../ui/button';
import { Card, CardContent } from '../ui/card';
import { Badge } from '../ui/badge';
import { Edit3, Trash2, Play, Monitor, Power, PowerOff } from 'lucide-react';

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

interface PresetListProps {
  presets: Preset[];
  onEdit: (preset: Preset) => void;
  onDelete: (id: string) => void;
  onToggle: (id: string) => void;
}

export function PresetList({
  presets,
  onEdit,
  onDelete,
  onToggle,
}: PresetListProps) {
  const handleApplyPreset = async (preset: Preset) => {
    if (!preset.enabled) return;

    try {
      if (window.electronAPI?.applyPreset) {
        const result = await window.electronAPI.applyPreset(preset);
        if (result.success) {
          console.log('Preset applied successfully:', preset.name);
        } else {
          console.error('Failed to apply preset:', result.error);
        }
      } else {
        console.log('Applying preset (dev mode):', preset);
      }
    } catch (error) {
      console.error('Error applying preset:', error);
    }
  };

  const enabledCount = presets.filter((p) => p.enabled).length;

  if (presets.length === 0) {
    return (
      <Card className="h-64 flex items-center justify-center">
        <div className="text-center space-y-4">
          <Monitor className="h-12 w-12 mx-auto text-muted-foreground" />
          <div>
            <h3 className="text-lg font-medium">No Presets Yet</h3>
            <p className="text-sm text-muted-foreground">
              Create your first preset to get started with window management
            </p>
          </div>
        </div>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      {/* Summary */}
      <div className="flex items-center justify-between p-4 bg-muted/30 rounded-lg">
        <div className="flex items-center gap-2">
          <Power className="h-4 w-4 text-green-600" />
          <span className="text-sm font-medium">
            {enabledCount} of {presets.length} presets active
          </span>
        </div>
        <Badge variant="outline" className="text-xs">
          {enabledCount} shortcuts enabled
        </Badge>
      </div>

      {/* Presets Grid */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {presets.map((preset) => (
          <Card
            key={preset.id}
            className={`group transition-all ${
              preset.enabled
                ? 'hover:shadow-md border-border'
                : 'opacity-60 border-dashed hover:opacity-80'
            }`}
          >
            <CardContent className="p-4">
              <div className="space-y-4">
                {/* Header with toggle */}
                <div className="flex items-center justify-between">
                  <h3 className="font-medium truncate flex-1">{preset.name}</h3>
                  <button
                    onClick={() => onToggle(preset.id)}
                    className={`p-1 rounded-full transition-colors ${
                      preset.enabled
                        ? 'text-green-600 hover:bg-green-100 dark:hover:bg-green-900/20'
                        : 'text-muted-foreground hover:bg-muted'
                    }`}
                    title={preset.enabled ? 'Disable preset' : 'Enable preset'}
                  >
                    {preset.enabled ? (
                      <Power className="h-4 w-4" />
                    ) : (
                      <PowerOff className="h-4 w-4" />
                    )}
                  </button>
                </div>

                {/* Preset Preview */}
                <div className="relative aspect-video bg-muted rounded border overflow-hidden">
                  <div className="absolute inset-1 bg-background rounded">
                    <div
                      className={`absolute border rounded transition-colors ${
                        preset.enabled
                          ? 'bg-primary/30 border-primary/50'
                          : 'bg-muted-foreground/20 border-muted-foreground/30'
                      }`}
                      style={{
                        left: `${preset.x}%`,
                        top: `${preset.y}%`,
                        width: `${preset.width}%`,
                        height: `${preset.height}%`,
                      }}
                    >
                      <div
                        className={`h-1 rounded-t ${
                          preset.enabled
                            ? 'bg-primary/50'
                            : 'bg-muted-foreground/30'
                        }`}
                      ></div>
                    </div>
                  </div>

                  {/* Disabled overlay */}
                  {!preset.enabled && (
                    <div className="absolute inset-0 bg-background/50 flex items-center justify-center">
                      <PowerOff className="h-6 w-6 text-muted-foreground" />
                    </div>
                  )}
                </div>

                {/* Preset Info */}
                <div className="space-y-2">
                  {preset.shortcut && (
                    <div className="flex justify-center">
                      <Badge
                        variant={preset.enabled ? 'default' : 'secondary'}
                        className={`text-xs ${
                          preset.enabled
                            ? 'bg-primary text-primary-foreground'
                            : 'bg-muted text-muted-foreground'
                        }`}
                      >
                        {preset.shortcut}
                      </Badge>
                    </div>
                  )}

                  <div className="text-xs text-muted-foreground space-y-1">
                    <div className="flex justify-between">
                      <span>Position:</span>
                      <span>
                        {Math.round(preset.x)}, {Math.round(preset.y)}{' '}
                        {preset.unit}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span>Size:</span>
                      <span>
                        {Math.round(preset.width)} × {Math.round(preset.height)}{' '}
                        {preset.unit}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Actions */}
                <div className="flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                  <Button
                    size="sm"
                    onClick={() => handleApplyPreset(preset)}
                    className="flex-1"
                    disabled={!preset.enabled}
                  >
                    <Play className="mr-1 h-3 w-3" />
                    Apply
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => onEdit(preset)}
                  >
                    <Edit3 className="h-3 w-3" />
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => onDelete(preset.id)}
                    className="text-destructive hover:text-destructive"
                  >
                    <Trash2 className="h-3 w-3" />
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
