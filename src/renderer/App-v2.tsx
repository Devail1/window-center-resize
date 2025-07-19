import { useState, useEffect } from 'react';
import {
  Monitor,
  Plus,
  Settings,
  Keyboard,
  Edit3,
  Moon,
  Sun,
  Grid3X3,
  Target,
} from 'lucide-react';
import { Button } from './components/ui/button';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from './components/ui/card';
import { Label } from './components/ui/label';
import { Switch } from './components/ui/switch';
import { Tabs, TabsContent, TabsList, TabsTrigger } from './components/ui/tabs';
import { Badge } from './components/ui/badge';
import { Separator } from './components/ui/separator';
import { VisualPresetEditor } from './components/v2-ui/visual-preset-editor';
import { PresetList } from './components/v2-ui/preset-list';
import { QuickActions } from './components/v2-ui/quick-actions';
import { ToggleGroups } from './components/v2-ui/toggle-groups';
import { useSettings } from './hooks/use-settings';
import './App.css';

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

export default function AppV2() {
  const {
    settings: appSettings,
    savePresets,
    saveToggleGroups,
    saveAppSettings,
    resetSettings,
    loading,
    error,
  } = useSettings();
  const [activeTab, setActiveTab] = useState('presets');
  const [selectedPreset, setSelectedPreset] = useState<Preset | null>(null);
  const [isEditing, setIsEditing] = useState(false);

  // Debug logging
  useEffect(() => {
    console.log('AppV2 mounted');
    console.log('Loading:', loading);
    console.log('Error:', error);
    console.log('AppSettings:', appSettings);
  }, [loading, error, appSettings]);

  // Apply dark mode to document
  useEffect(() => {
    if (appSettings?.settings?.darkMode) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }, [appSettings?.settings?.darkMode]);

  // Show loading state
  if (loading) {
    return (
      <div className="min-h-screen bg-background text-foreground flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto mb-4" />
          <p>Loading settings...</p>
        </div>
      </div>
    );
  }

  // Show error state
  if (error) {
    return (
      <div className="min-h-screen bg-background text-foreground flex items-center justify-center">
        <div className="text-center">
          <p className="text-destructive mb-4">Error: {error}</p>
          <Button onClick={() => window.location.reload()}>Retry</Button>
        </div>
      </div>
    );
  }

  // Use settings from the hook or fallback to defaults
  const presets = appSettings?.presets || [
    {
      id: '1',
      name: 'Center Large',
      x: 20,
      y: 10,
      width: 60,
      height: 80,
      shortcut: 'Ctrl+Alt+C',
      unit: '%' as const,
      enabled: true,
    },
    {
      id: '2',
      name: 'Left Half',
      x: 0,
      y: 0,
      width: 50,
      height: 100,
      shortcut: 'Ctrl+Alt+L',
      unit: '%' as const,
      enabled: true,
    },
    {
      id: '3',
      name: 'Right Half',
      x: 50,
      y: 0,
      width: 50,
      height: 100,
      shortcut: 'Ctrl+Alt+R',
      unit: '%' as const,
      enabled: false,
    },
  ];

  const toggleGroups = appSettings?.toggleGroups || [
    {
      id: '1',
      name: 'Work Layout',
      shortcut: 'Ctrl+Alt+Tab',
      presetIds: ['1', '2'],
      currentIndex: 0,
      enabled: true,
    },
    {
      id: '2',
      name: 'Split Views',
      shortcut: 'Ctrl+Alt+Space',
      presetIds: ['2', '3'],
      currentIndex: 0,
      enabled: true,
    },
  ];

  const settings = appSettings?.settings || {
    centeringEnabled: true,
    resizingEnabled: true,
    positioningEnabled: true,
    startWithWindows: false,
    showNotifications: true,
    darkMode: false,
  };

  const handleToggleDarkMode = async () => {
    const newDarkMode = !settings.darkMode;
    const updatedSettings = {
      ...settings,
      darkMode: newDarkMode,
    };
    await saveAppSettings(updatedSettings);
  };

  const handleCreatePreset = async () => {
    const newPreset: Preset = {
      id: Date.now().toString(),
      name: 'New Preset',
      x: 25,
      y: 25,
      width: 50,
      height: 50,
      shortcut: '',
      unit: '%' as const,
      enabled: true,
    };
    const updatedPresets = [...presets, newPreset];
    await savePresets(updatedPresets);
    setSelectedPreset(newPreset);
    setIsEditing(true);
    setActiveTab('editor');
  };

  const handleEditPreset = (preset: Preset) => {
    setSelectedPreset(preset);
    setIsEditing(true);
    setActiveTab('editor');
  };

  const handleDeletePreset = async (id: string) => {
    const updatedPresets = presets.filter((p) => p.id !== id);
    await savePresets(updatedPresets);
    if (selectedPreset?.id === id) {
      setSelectedPreset(null);
      setIsEditing(false);
    }
  };

  const handleSavePreset = async (updatedPreset: Preset) => {
    const updatedPresets = presets.map((p) =>
      p.id === updatedPreset.id ? updatedPreset : p,
    );
    await savePresets(updatedPresets);
    setSelectedPreset(updatedPreset);
    setIsEditing(false);
  };

  const handleTogglePreset = async (id: string) => {
    const updatedPresets = presets.map((p) =>
      p.id === id ? { ...p, enabled: !p.enabled } : p,
    );
    await savePresets(updatedPresets);
  };

  const handleCreateToggleGroup = async () => {
    const newGroup: ToggleGroup = {
      id: Date.now().toString(),
      name: 'New Toggle Group',
      shortcut: '',
      presetIds: [],
      currentIndex: 0,
      enabled: true,
    };
    const updatedGroups = [...toggleGroups, newGroup];
    await saveToggleGroups(updatedGroups);
  };

  const handleEditToggleGroup = (group: ToggleGroup) => {
    console.log('Edit toggle group:', group);
  };

  const handleDeleteToggleGroup = async (id: string) => {
    const updatedGroups = toggleGroups.filter((g) => g.id !== id);
    await saveToggleGroups(updatedGroups);
  };

  const handleToggleToggleGroup = async (id: string) => {
    const updatedGroups = toggleGroups.map((g) =>
      g.id === id ? { ...g, enabled: !g.enabled } : g,
    );
    await saveToggleGroups(updatedGroups);
  };

  return (
    <div className="min-h-screen transition-colors">
      <div className="min-h-screen bg-background text-foreground">
        {/* Header */}
        <header className="border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
          <div className="container flex h-16 items-center justify-between px-6">
            <div className="flex items-center gap-3">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary text-primary-foreground">
                <Monitor className="h-4 w-4" />
              </div>
              <div>
                <h1 className="text-lg font-semibold">
                  Window Center & Resizer
                </h1>
                <p className="text-xs text-muted-foreground">
                  Keyboard-first window management
                </p>
              </div>
            </div>

            <div className="flex items-center gap-2">
              <Button
                variant="ghost"
                size="icon"
                onClick={handleToggleDarkMode}
                className="h-8 w-8"
              >
                {settings.darkMode ? (
                  <Sun className="h-4 w-4" />
                ) : (
                  <Moon className="h-4 w-4" />
                )}
              </Button>
              <Badge variant="secondary" className="text-xs">
                <Keyboard className="mr-1 h-3 w-3" />
                Ctrl+Alt+W
              </Badge>
            </div>
          </div>
        </header>

        {/* Main Content */}
        <div className="container px-6 py-6">
          <Tabs
            value={activeTab}
            onValueChange={setActiveTab}
            className="space-y-6"
          >
            <TabsList className="grid w-full grid-cols-4">
              <TabsTrigger value="presets" className="flex items-center gap-2">
                <Grid3X3 className="h-4 w-4" />
                Presets
              </TabsTrigger>
              <TabsTrigger value="editor" className="flex items-center gap-2">
                <Edit3 className="h-4 w-4" />
                Editor
              </TabsTrigger>
              <TabsTrigger value="quick" className="flex items-center gap-2">
                <Target className="h-4 w-4" />
                Quick Actions
              </TabsTrigger>
              <TabsTrigger value="settings" className="flex items-center gap-2">
                <Settings className="h-4 w-4" />
                Settings
              </TabsTrigger>
            </TabsList>

            <TabsContent value="presets" className="space-y-6">
              <div className="flex items-center justify-between">
                <div>
                  <h2 className="text-2xl font-bold">Window Presets</h2>
                  <p className="text-muted-foreground">
                    Manage your saved window positions and sizes
                  </p>
                </div>
                <Button
                  onClick={handleCreatePreset}
                  className="flex items-center gap-2"
                >
                  <Plus className="h-4 w-4" />
                  New Preset
                </Button>
              </div>

              <PresetList
                presets={presets}
                onEdit={handleEditPreset}
                onDelete={handleDeletePreset}
                onToggle={handleTogglePreset}
              />

              <ToggleGroups
                toggleGroups={toggleGroups}
                presets={presets}
                onCreate={handleCreateToggleGroup}
                onEdit={handleEditToggleGroup}
                onDelete={handleDeleteToggleGroup}
                onToggle={handleToggleToggleGroup}
              />
            </TabsContent>

            <TabsContent value="editor" className="space-y-6">
              <div>
                <h2 className="text-2xl font-bold">Visual Preset Editor</h2>
                <p className="text-muted-foreground">
                  Drag and resize to position your window precisely
                </p>
              </div>

              <VisualPresetEditor
                preset={selectedPreset}
                isEditing={isEditing}
                onSave={handleSavePreset}
                onCancel={() => {
                  setIsEditing(false);
                  setSelectedPreset(null);
                }}
              />
            </TabsContent>

            <TabsContent value="quick" className="space-y-6">
              <div>
                <h2 className="text-2xl font-bold">Quick Actions</h2>
                <p className="text-muted-foreground">
                  Instant window management without presets
                </p>
              </div>

              <QuickActions />
            </TabsContent>

            <TabsContent value="settings" className="space-y-6">
              <div>
                <h2 className="text-2xl font-bold">Settings</h2>
                <p className="text-muted-foreground">
                  Configure your window management preferences
                </p>
              </div>

              <div className="grid gap-6">
                <Card>
                  <CardHeader>
                    <CardTitle>Features</CardTitle>
                    <CardDescription>
                      Enable or disable specific window management features
                    </CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div className="flex items-center justify-between">
                      <div className="space-y-0.5">
                        <Label>Window Centering</Label>
                        <p className="text-sm text-muted-foreground">
                          Allow centering windows with keyboard shortcuts
                        </p>
                      </div>
                      <Switch
                        checked={settings.centeringEnabled}
                        onCheckedChange={async (checked: boolean) => {
                          const updatedSettings = {
                            ...settings,
                            centeringEnabled: checked,
                          };
                          await saveAppSettings(updatedSettings);
                        }}
                      />
                    </div>

                    <Separator />

                    <div className="flex items-center justify-between">
                      <div className="space-y-0.5">
                        <Label>Window Resizing</Label>
                        <p className="text-sm text-muted-foreground">
                          Allow resizing windows to predefined sizes
                        </p>
                      </div>
                      <Switch
                        checked={settings.resizingEnabled}
                        onCheckedChange={async (checked: boolean) => {
                          const updatedSettings = {
                            ...settings,
                            resizingEnabled: checked,
                          };
                          await saveAppSettings(updatedSettings);
                        }}
                      />
                    </div>

                    <Separator />

                    <div className="flex items-center justify-between">
                      <div className="space-y-0.5">
                        <Label>Window Positioning</Label>
                        <p className="text-sm text-muted-foreground">
                          Allow precise window positioning
                        </p>
                      </div>
                      <Switch
                        checked={settings.positioningEnabled}
                        onCheckedChange={async (checked: boolean) => {
                          const updatedSettings = {
                            ...settings,
                            positioningEnabled: checked,
                          };
                          await saveAppSettings(updatedSettings);
                        }}
                      />
                    </div>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader>
                    <CardTitle>System</CardTitle>
                    <CardDescription>
                      System integration and startup options
                    </CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div className="flex items-center justify-between">
                      <div className="space-y-0.5">
                        <Label>Start with Windows</Label>
                        <p className="text-sm text-muted-foreground">
                          Launch automatically when Windows starts
                        </p>
                      </div>
                      <Switch
                        checked={settings.startWithWindows}
                        onCheckedChange={async (checked: boolean) => {
                          const updatedSettings = {
                            ...settings,
                            startWithWindows: checked,
                          };
                          await saveAppSettings(updatedSettings);
                        }}
                      />
                    </div>

                    <Separator />

                    <div className="flex items-center justify-between">
                      <div className="space-y-0.5">
                        <Label>Show Notifications</Label>
                        <p className="text-sm text-muted-foreground">
                          Display notifications when actions are performed
                        </p>
                      </div>
                      <Switch
                        checked={settings.showNotifications}
                        onCheckedChange={async (checked: boolean) => {
                          const updatedSettings = {
                            ...settings,
                            showNotifications: checked,
                          };
                          await saveAppSettings(updatedSettings);
                        }}
                      />
                    </div>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader>
                    <CardTitle>Reset Settings</CardTitle>
                    <CardDescription>
                      Reset all window management settings to default
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <Button
                      variant="destructive"
                      onClick={resetSettings}
                      className="w-full"
                    >
                      Reset Settings
                    </Button>
                  </CardContent>
                </Card>
              </div>
            </TabsContent>
          </Tabs>
        </div>
      </div>
    </div>
  );
}
