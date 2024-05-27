import './TabsList.css';
import { useTabsContext } from '@/renderer/providers/TabsProvider';
import { TTabAction } from '@/renderer/components/AppContainer/AppContainer';
import { useSettingsContext } from '@/renderer/providers/SettingsProvider';

function TabsList() {
  const { resetSettings } = useSettingsContext();

  const { activeTab, setActiveTab } = useTabsContext();

  const handleClick = (tabName: TTabAction) => {
    setActiveTab(tabName);
  };

  const handleReset = () => {
    resetSettings();
  };

  return (
    <div className="nav">
      <div className="tab">
        <button
          type="button"
          className={`tablinks ${activeTab === 'center' ? 'active' : ''}`}
          onClick={() => handleClick('center')}
        >
          Center Window
        </button>
        <button
          type="button"
          className={`tablinks ${activeTab === 'resize' ? 'active' : ''}`}
          onClick={() => handleClick('resize')}
        >
          Resize Window
        </button>
      </div>
      <button id="reset-button" type="button" onClick={handleReset}>
        Reset
      </button>
    </div>
  );
}

export default TabsList;
