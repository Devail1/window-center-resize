'use client';

import type React from 'react';

import { useState } from 'react';
import { Button } from '../ui/button';
import { Card, CardContent } from '../ui/card';
import { Badge } from '../ui/badge';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Separator } from '../ui/separator';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '../ui/dialog';
import {
  RotateCcw,
  Plus,
  Edit3,
  Trash2,
  Power,
  PowerOff,
  Play,
  ArrowRight,
  GripVertical,
  Check,
  X,
  AlertTriangle,
} from 'lucide-react';

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

interface ToggleGroup {
  id: string;
  name: string;
  shortcut: string;
  presetIds: string[];
  currentIndex: number;
  enabled: boolean;
}

interface ToggleGroupsProps {
  toggleGroups: ToggleGroup[];
  presets: Preset[];
  onCreate: () => void;
  onEdit: (group: ToggleGroup) => void;
  onDelete: (id: string) => void;
  onToggle: (id: string) => void;
}

export function ToggleGroups({
  toggleGroups,
  presets,
  onCreate,
  onEdit,
  onDelete,
  onToggle,
}: ToggleGroupsProps) {
  const [editingGroup, setEditingGroup] = useState<ToggleGroup | null>(null);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingShortcut, setEditingShortcut] = useState(false);
  const [tempShortcut, setTempShortcut] = useState('');
  const [shortcutConflict, setShortcutConflict] = useState<string | null>(null);

  const handleCycleGroup = async (group: ToggleGroup) => {
    if (!group.enabled || group.presetIds.length === 0) return;

    const nextIndex = (group.currentIndex + 1) % group.presetIds.length;
    const currentPresetId = group.presetIds[nextIndex];
    const currentPreset = presets.find((p) => p.id === currentPresetId);

    if (currentPreset && currentPreset.enabled) {
      try {
        if (window.electronAPI?.applyPreset) {
          const result = await window.electronAPI.applyPreset(currentPreset);
          if (result.success) {
            console.log('Preset applied successfully:', currentPreset.name);
            showNotification(`Applied: ${currentPreset.name}`);
          } else {
            console.error('Failed to apply preset:', result.error);
          }
        } else {
          console.log('Cycling to preset (dev mode):', currentPreset.name);
          showNotification(`Applied: ${currentPreset.name}`);
        }
      } catch (error) {
        console.error('Error applying preset:', error);
      }
    }
  };

  const showNotification = (message: string) => {
    // In a real app, this would show a lightweight HUD notification
    console.log('Notification:', message);
  };

  const handleEditGroup = (group: ToggleGroup) => {
    setEditingGroup({ ...group });
    setTempShortcut(group.shortcut);
    setIsDialogOpen(true);
  };

  const handleSaveGroup = () => {
    if (!editingGroup) return;

    // Check for shortcut conflicts
    const conflict = toggleGroups.find(
      (g) =>
        g.id !== editingGroup.id &&
        g.shortcut.toLowerCase() === tempShortcut.toLowerCase(),
    );

    if (conflict && tempShortcut) {
      setShortcutConflict(conflict.name);
      return;
    }

    const updatedGroup = { ...editingGroup, shortcut: tempShortcut };
    // In a real app, this would update the group
    console.log('Saving group:', updatedGroup);

    setIsDialogOpen(false);
    setEditingGroup(null);
    setShortcutConflict(null);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    e.preventDefault();
    const keys = [];

    if (e.ctrlKey) keys.push('Ctrl');
    if (e.altKey) keys.push('Alt');
    if (e.shiftKey) keys.push('Shift');
    if (e.metaKey) keys.push('Cmd');

    if (e.key && !['Control', 'Alt', 'Shift', 'Meta'].includes(e.key)) {
      let key = e.key;
      if (key === 'ArrowLeft') key = '←';
      if (key === 'ArrowRight') key = '→';
      if (key === 'ArrowUp') key = '↑';
      if (key === 'ArrowDown') key = '↓';
      if (key === ' ') key = 'Space';
      if (key === 'Tab') key = 'Tab';
      keys.push(key.charAt(0).toUpperCase() + key.slice(1));
    }

    if (keys.length > 1) {
      setTempShortcut(keys.join('+'));
      setShortcutConflict(null);
    }
  };

  const getPresetName = (presetId: string) => {
    const preset = presets.find((p) => p.id === presetId);
    return preset?.name || 'Unknown Preset';
  };

  const getCurrentPreset = (group: ToggleGroup) => {
    if (group.presetIds.length === 0) return null;
    const currentPresetId = group.presetIds[group.currentIndex];
    return presets.find((p) => p.id === currentPresetId);
  };

  const enabledCount = toggleGroups.filter((g) => g.enabled).length;

  return (
    <div className="space-y-4">
      <Separator />

      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-lg font-semibold">Toggle Groups</h3>
          <p className="text-sm text-muted-foreground">
            Cycle through presets with a single keyboard shortcut
          </p>
        </div>
        <Button
          onClick={onCreate}
          variant="outline"
          size="sm"
          className="flex items-center gap-2 bg-transparent"
        >
          <Plus className="h-4 w-4" />
          New Group
        </Button>
      </div>

      {toggleGroups.length === 0 ? (
        <Card className="h-32 flex items-center justify-center">
          <div className="text-center space-y-2">
            <RotateCcw className="h-8 w-8 mx-auto text-muted-foreground" />
            <div>
              <h4 className="font-medium">No Toggle Groups</h4>
              <p className="text-xs text-muted-foreground">
                Create groups to cycle through presets quickly
              </p>
            </div>
          </div>
        </Card>
      ) : (
        <>
          {/* Summary */}
          <div className="flex items-center justify-between p-3 bg-muted/30 rounded-lg">
            <div className="flex items-center gap-2">
              <RotateCcw className="h-4 w-4 text-blue-600" />
              <span className="text-sm font-medium">
                {enabledCount} of {toggleGroups.length} groups active
              </span>
            </div>
            <Badge variant="outline" className="text-xs">
              {enabledCount} cycle shortcuts
            </Badge>
          </div>

          {/* Toggle Groups List */}
          <div className="grid gap-3">
            {toggleGroups.map((group) => {
              const currentPreset = getCurrentPreset(group);
              return (
                <Card
                  key={group.id}
                  className={`group transition-all ${
                    group.enabled
                      ? 'hover:shadow-sm border-border'
                      : 'opacity-60 border-dashed hover:opacity-80'
                  }`}
                >
                  <CardContent className="p-4">
                    <div className="flex items-center gap-4">
                      {/* Group Info */}
                      <div className="flex-1 space-y-2">
                        <div className="flex items-center gap-2">
                          <h4 className="font-medium">{group.name}</h4>
                          <button
                            onClick={() => onToggle(group.id)}
                            className={`p-1 rounded-full transition-colors ${
                              group.enabled
                                ? 'text-blue-600 hover:bg-blue-100 dark:hover:bg-blue-900/20'
                                : 'text-muted-foreground hover:bg-muted'
                            }`}
                            title={
                              group.enabled ? 'Disable group' : 'Enable group'
                            }
                          >
                            {group.enabled ? (
                              <Power className="h-3 w-3" />
                            ) : (
                              <PowerOff className="h-3 w-3" />
                            )}
                          </button>
                        </div>

                        {/* Preset Chain */}
                        <div className="flex items-center gap-1 text-xs">
                          {group.presetIds.map((presetId, index) => (
                            <div
                              key={presetId}
                              className="flex items-center gap-1"
                            >
                              <Badge
                                variant={
                                  index === group.currentIndex
                                    ? 'default'
                                    : 'secondary'
                                }
                                className={`text-xs ${
                                  index === group.currentIndex
                                    ? 'bg-blue-600 text-white'
                                    : 'bg-muted text-muted-foreground'
                                }`}
                              >
                                {getPresetName(presetId)}
                              </Badge>
                              {index < group.presetIds.length - 1 && (
                                <ArrowRight className="h-3 w-3 text-muted-foreground" />
                              )}
                            </div>
                          ))}
                          {group.presetIds.length === 0 && (
                            <span className="text-muted-foreground">
                              No presets assigned
                            </span>
                          )}
                        </div>

                        {/* Current Status */}
                        {currentPreset && (
                          <div className="text-xs text-muted-foreground">
                            Current:{' '}
                            <span className="font-medium">
                              {currentPreset.name}
                            </span>
                          </div>
                        )}
                      </div>

                      {/* Shortcut & Actions */}
                      <div className="flex items-center gap-2">
                        {group.shortcut && (
                          <Badge
                            variant={group.enabled ? 'default' : 'secondary'}
                            className={`text-xs ${
                              group.enabled
                                ? 'bg-blue-600 text-white'
                                : 'bg-muted text-muted-foreground'
                            }`}
                          >
                            {group.shortcut}
                          </Badge>
                        )}

                        <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => handleCycleGroup(group)}
                            disabled={
                              !group.enabled || group.presetIds.length === 0
                            }
                            className="h-7 w-7 p-0"
                            title="Test cycle"
                          >
                            <Play className="h-3 w-3" />
                          </Button>
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => handleEditGroup(group)}
                            className="h-7 w-7 p-0"
                          >
                            <Edit3 className="h-3 w-3" />
                          </Button>
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => onDelete(group.id)}
                            className="h-7 w-7 p-0 text-destructive hover:text-destructive"
                          >
                            <Trash2 className="h-3 w-3" />
                          </Button>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              );
            })}
          </div>
        </>
      )}

      {/* Edit Dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Edit Toggle Group</DialogTitle>
            <DialogDescription>
              Configure your toggle group settings and preset order
            </DialogDescription>
          </DialogHeader>

          {editingGroup && (
            <div className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="group-name">Group Name</Label>
                <Input
                  id="group-name"
                  value={editingGroup.name}
                  onChange={(e) =>
                    setEditingGroup({ ...editingGroup, name: e.target.value })
                  }
                  placeholder="Enter group name"
                />
              </div>

              <div className="space-y-2">
                <Label>Keyboard Shortcut</Label>
                <div className="flex gap-2">
                  {editingShortcut ? (
                    <>
                      <Input
                        value={tempShortcut}
                        onChange={(e) => setTempShortcut(e.target.value)}
                        onKeyDown={handleKeyDown}
                        className="flex-1"
                        placeholder="Press keys..."
                        autoFocus
                      />
                      <Button
                        size="sm"
                        onClick={() => setEditingShortcut(false)}
                      >
                        <Check className="h-4 w-4" />
                      </Button>
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => {
                          setEditingShortcut(false);
                          setTempShortcut(editingGroup.shortcut);
                          setShortcutConflict(null);
                        }}
                      >
                        <X className="h-4 w-4" />
                      </Button>
                    </>
                  ) : (
                    <>
                      <Input
                        value={tempShortcut}
                        readOnly
                        className="flex-1 cursor-pointer"
                        onClick={() => setEditingShortcut(true)}
                        placeholder="Click to set shortcut"
                      />
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => setEditingShortcut(true)}
                      >
                        <Edit3 className="h-4 w-4" />
                      </Button>
                    </>
                  )}
                </div>
                {shortcutConflict && (
                  <div className="flex items-center gap-2 text-yellow-600 text-sm">
                    <AlertTriangle className="h-4 w-4" />
                    Conflict with "{shortcutConflict}"
                  </div>
                )}
              </div>

              <div className="space-y-2">
                <Label>Preset Order</Label>
                <div className="space-y-2 max-h-32 overflow-y-auto">
                  {editingGroup.presetIds.map((presetId, index) => (
                    <div
                      key={presetId}
                      className="flex items-center gap-2 p-2 bg-muted/50 rounded"
                    >
                      <GripVertical className="h-4 w-4 text-muted-foreground" />
                      <span className="flex-1 text-sm">
                        {getPresetName(presetId)}
                      </span>
                      <Badge variant="outline" className="text-xs">
                        {index + 1}
                      </Badge>
                    </div>
                  ))}
                  {editingGroup.presetIds.length === 0 && (
                    <div className="text-center py-4 text-muted-foreground text-sm">
                      No presets assigned
                    </div>
                  )}
                </div>
              </div>

              <div className="flex gap-2 pt-4">
                <Button onClick={handleSaveGroup} className="flex-1">
                  Save Changes
                </Button>
                <Button
                  variant="outline"
                  onClick={() => {
                    setIsDialogOpen(false);
                    setEditingGroup(null);
                    setShortcutConflict(null);
                  }}
                  className="flex-1"
                >
                  Cancel
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
