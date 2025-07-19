'use client';

import type React from 'react';

import { useState } from 'react';
import { Button } from '../ui/button';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '../ui/card';
import { Badge } from '../ui/badge';
import { Input } from '../ui/input';
import {
  Monitor,
  Maximize2,
  RotateCcw,
  ArrowLeft,
  ArrowRight,
  ArrowUp,
  ArrowDown,
  Target,
  Power,
  PowerOff,
  Edit3,
  Check,
  X,
  AlertTriangle,
} from 'lucide-react';

interface QuickAction {
  id: string;
  name: string;
  description: string;
  shortcut: string;
  icon: React.ComponentType<{ className?: string }>;
  enabled: boolean;
  action: () => void;
}

export function QuickActions() {
  const [editingShortcut, setEditingShortcut] = useState<string | null>(null);
  const [tempShortcut, setTempShortcut] = useState('');
  const [shortcutConflict, setShortcutConflict] = useState<string | null>(null);

  const [quickActions, setQuickActions] = useState<QuickAction[]>([
    {
      id: 'center',
      name: 'Center Window',
      description: 'Center the active window on screen',
      shortcut: 'Ctrl+Alt+C',
      icon: Target,
      enabled: true,
      action: () => console.log('Center window'),
    },
    {
      id: 'maximize',
      name: 'Maximize',
      description: 'Maximize the active window',
      shortcut: 'Ctrl+Alt+M',
      icon: Maximize2,
      enabled: true,
      action: () => console.log('Maximize window'),
    },
    {
      id: 'restore',
      name: 'Restore',
      description: 'Restore window to previous size',
      shortcut: 'Ctrl+Alt+R',
      icon: RotateCcw,
      enabled: false,
      action: () => console.log('Restore window'),
    },
    {
      id: 'left',
      name: 'Move Left',
      description: 'Move window to left half of screen',
      shortcut: 'Ctrl+Alt+←',
      icon: ArrowLeft,
      enabled: true,
      action: () => console.log('Move left'),
    },
    {
      id: 'right',
      name: 'Move Right',
      description: 'Move window to right half of screen',
      shortcut: 'Ctrl+Alt+→',
      icon: ArrowRight,
      enabled: true,
      action: () => console.log('Move right'),
    },
    {
      id: 'up',
      name: 'Move Up',
      description: 'Move window to top half of screen',
      shortcut: 'Ctrl+Alt+↑',
      icon: ArrowUp,
      enabled: false,
      action: () => console.log('Move up'),
    },
    {
      id: 'down',
      name: 'Move Down',
      description: 'Move window to bottom half of screen',
      shortcut: 'Ctrl+Alt+↓',
      icon: ArrowDown,
      enabled: false,
      action: () => console.log('Move down'),
    },
  ]);

  const toggleAction = (id: string) => {
    setQuickActions((actions) =>
      actions.map((action) =>
        action.id === id ? { ...action, enabled: !action.enabled } : action,
      ),
    );
  };

  const startEditingShortcut = (id: string, currentShortcut: string) => {
    setEditingShortcut(id);
    setTempShortcut(currentShortcut);
    setShortcutConflict(null);
  };

  const saveShortcut = (id: string) => {
    // Check for conflicts
    const conflict = quickActions.find(
      (action) =>
        action.id !== id &&
        action.shortcut.toLowerCase() === tempShortcut.toLowerCase(),
    );

    if (conflict) {
      setShortcutConflict(conflict.name);
      return;
    }

    setQuickActions((actions) =>
      actions.map((action) =>
        action.id === id ? { ...action, shortcut: tempShortcut } : action,
      ),
    );

    setEditingShortcut(null);
    setTempShortcut('');
    setShortcutConflict(null);
  };

  const cancelEditingShortcut = () => {
    setEditingShortcut(null);
    setTempShortcut('');
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
      keys.push(key.toUpperCase());
    }

    if (keys.length > 1) {
      setTempShortcut(keys.join('+'));
      setShortcutConflict(null);
    }
  };

  const enabledCount = quickActions.filter((action) => action.enabled).length;

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Monitor className="h-5 w-5" />
            Window Actions
          </CardTitle>
          <CardDescription>
            Quick actions for immediate window management
          </CardDescription>
        </CardHeader>
        <CardContent>
          {/* Summary */}
          <div className="flex items-center justify-between p-4 mb-4 bg-muted/30 rounded-lg">
            <div className="flex items-center gap-2">
              <Power className="h-4 w-4 text-green-600" />
              <span className="text-sm font-medium">
                {enabledCount} of {quickActions.length} actions active
              </span>
            </div>
            <Badge variant="outline" className="text-xs">
              {enabledCount} shortcuts enabled
            </Badge>
          </div>

          <div className="grid gap-3 md:grid-cols-2">
            {quickActions.map((action) => (
              <div key={action.name} className="relative group">
                <Button
                  variant="outline"
                  className={`h-auto p-4 justify-start w-full transition-all ${
                    action.enabled
                      ? 'bg-primary/5 border-primary/30 hover:bg-primary/10'
                      : 'bg-transparent opacity-60 hover:opacity-80 border-dashed'
                  }`}
                  onClick={action.enabled ? action.action : undefined}
                  disabled={!action.enabled}
                >
                  <div className="flex items-center gap-3 w-full">
                    <action.icon
                      className={`h-5 w-5 ${
                        action.enabled
                          ? 'text-primary'
                          : 'text-muted-foreground'
                      }`}
                    />
                    <div className="flex-1 text-left">
                      <div className="font-medium">{action.name}</div>
                      <div className="text-xs text-muted-foreground">
                        {action.description}
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      {editingShortcut === action.id ? (
                        <div className="flex items-center gap-1">
                          <Input
                            value={tempShortcut}
                            onChange={(e) => setTempShortcut(e.target.value)}
                            onKeyDown={handleKeyDown}
                            className="w-32 h-6 text-xs"
                            placeholder="Press keys..."
                            autoFocus
                          />
                          <Button
                            size="sm"
                            variant="ghost"
                            className="h-6 w-6 p-0"
                            onClick={() => saveShortcut(action.id)}
                          >
                            <Check className="h-3 w-3" />
                          </Button>
                          <Button
                            size="sm"
                            variant="ghost"
                            className="h-6 w-6 p-0"
                            onClick={cancelEditingShortcut}
                          >
                            <X className="h-3 w-3" />
                          </Button>
                        </div>
                      ) : (
                        <div className="flex items-center gap-1">
                          <Badge
                            variant={action.enabled ? 'default' : 'secondary'}
                            className={`text-xs cursor-pointer hover:bg-primary/80 ${
                              action.enabled
                                ? 'bg-primary text-primary-foreground'
                                : 'bg-muted text-muted-foreground'
                            }`}
                            onClick={() =>
                              startEditingShortcut(action.id, action.shortcut)
                            }
                          >
                            {action.shortcut}
                          </Badge>
                          <Button
                            size="sm"
                            variant="ghost"
                            className="h-6 w-6 p-0 opacity-0 group-hover:opacity-100"
                            onClick={() =>
                              startEditingShortcut(action.id, action.shortcut)
                            }
                          >
                            <Edit3 className="h-3 w-3" />
                          </Button>
                        </div>
                      )}
                    </div>
                  </div>
                </Button>

                {/* Toggle indicator */}
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    toggleAction(action.id);
                  }}
                  className={`absolute top-2 right-2 w-4 h-4 rounded-full transition-all opacity-0 group-hover:opacity-100 ${
                    action.enabled
                      ? 'text-green-600 hover:bg-green-100 dark:hover:bg-green-900/20'
                      : 'text-muted-foreground hover:bg-muted'
                  }`}
                  title={action.enabled ? 'Disable action' : 'Enable action'}
                >
                  {action.enabled ? (
                    <Power className="w-4 h-4" />
                  ) : (
                    <PowerOff className="w-4 h-4" />
                  )}
                </button>
              </div>
            ))}
          </div>

          {/* Shortcut conflict warning */}
          {shortcutConflict && (
            <div className="mt-4 p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
              <div className="flex items-center gap-2 text-yellow-800 dark:text-yellow-200">
                <AlertTriangle className="h-4 w-4" />
                <span className="text-sm">
                  Shortcut conflict: "{tempShortcut}" is already used by{' '}
                  {shortcutConflict}
                </span>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Active Keyboard Shortcuts</CardTitle>
          <CardDescription>
            Currently enabled shortcuts for quick access
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            <div className="flex items-center justify-between py-2 border-b">
              <span className="text-sm">Show/Hide App</span>
              <Badge variant="outline">Ctrl+Alt+W</Badge>
            </div>
            {quickActions
              .filter((action) => action.enabled)
              .map((action) => (
                <div
                  key={action.id}
                  className="flex items-center justify-between py-2 border-b last:border-b-0"
                >
                  <span className="text-sm">{action.name}</span>
                  <Badge
                    variant="outline"
                    className="bg-primary/5 border-primary/30 cursor-pointer hover:bg-primary/10"
                    onClick={() =>
                      startEditingShortcut(action.id, action.shortcut)
                    }
                  >
                    {action.shortcut}
                  </Badge>
                </div>
              ))}
            {enabledCount === 0 && (
              <div className="text-center py-4 text-muted-foreground text-sm">
                No shortcuts currently active
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
